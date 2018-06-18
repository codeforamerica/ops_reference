require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  describe '#index' do
    it 'returns a successful response' do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end
end
