require 'rails_helper'

RSpec.describe "posts:create", type: :rake do
  include_context 'rake'
  before { ActiveJob::Base.queue_adapter = :test }

  describe 'posts:create' do
    it 'creates a post and enqueues it' do
      post = Post.create name: 'a name'
      allow(Post).to receive(:create).and_return(post)

      expect {
        task.invoke
      }.to have_enqueued_job(ProcessPostJob).with(post)
    end
  end
end