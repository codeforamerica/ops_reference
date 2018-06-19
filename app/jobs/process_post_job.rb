class ProcessPostJob < ApplicationJob
  queue_as :default

  def perform(post)
    Rails.logger.info "Performing ProcessPostJob"
    post.update! processed: true
  end
end
