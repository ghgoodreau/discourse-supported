# name: discourse-supported
# about: Mark topics as supported when they've reached a certain threshold
# version: 0.1.1
# authors: Thomas Hart II && Hunter Goodreau
# url: https://github.com/myrridin/discourse-supported

after_initialize do
  class ::Post
    after_create :check_for_support

    def check_for_support
      needs_support_tag = Tag.find_or_create_by(name: 'Needs-Support')
      supported_tag = Tag.find_or_create_by(name: 'Supported')

      if is_first_post?
        # If it's the first post, add the needs support tag
        topic.tags << needs_support_tag
      else
	supported = !topic.tags.include?(needs_support_tag)
	newly_supported = false

        unless supported
          # If it's not the first post and it has a needs support tag, check the support threshold and modify tags as necessary

	  replies = topic.posts.where('post_number > 1')
          reply_word_count = replies.sum(:word_count)
	
	  # If there are replies and the word count of the replies is over 300, delete the 'needs support' tag
	  if(replies.length >= 1 && reply_word_count >= 300)
            topic.tags.delete needs_support_tag
	    supported = true
	    newly_supported = true
          end
	end

	Rails.logger.info("POSTING TO HSAPPS")
	uri = URI('http://hsapps.thomashart.me/twilio/discourse_webhook')
	res = Net::HTTP.post_form(uri, topic_id: topic_id, supported: supported, newly_supported: newly_supported, body: cooked, username: user.username)
      end

      Rails.logger.info("CHECKING FOR SUPPORT ON #{self}")
    end
  end
end
