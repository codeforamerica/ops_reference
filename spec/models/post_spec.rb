require 'rails_helper'

RSpec.describe Post, type: :model do
  describe '#name' do
    it "is required" do
      post = Post.new
      expect(post).not_to be_valid
      expect(post.errors[:name]).to be_present
    end
  end
end
