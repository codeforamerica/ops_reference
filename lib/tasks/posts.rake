namespace :posts do
  desc "Enqeueus post process job"
  task create: :environment do
    post = Post.create name: Faker::Superhero.name
    ProcessPostJob.perform_later(post)
  end
end
