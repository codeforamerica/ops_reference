require 'rails_helper'

RSpec.describe ProcessPostJob, type: :job do
  before { ActiveJob::Base.queue_adapter = :test }

  let(:post) { Post.create name: "a title" }

  it "marks the post as processed" do
    expect {
      ProcessPostJob.perform_now(post)
    }.to change { post.reload.processed }.from(false).to(true)
  end

  it "enqueues on the default queue" do
    expect {
      described_class.perform_later(post)
    }.to have_enqueued_job.on_queue("default")
  end
end
