require "rails_helper"

RSpec.describe Task::AddAttachment do
  let(:user) {User.create!(email: 'user@user.user', password: '12345678')}
  let(:another_user) {
    User.create!(email: 'another_user@user.user', password: '12345678')
  }
  let(:task) {
    attachments = [
      {file: FilelessIO.from('image/png', 'digits.png', '123')},
      {file: FilelessIO.from('image/jpeg', 'digits.jpg', '456')}
    ]
    Task::Create.(
      name: 'Hi!', description: 'Hello!', user_id: user.id,
      attachments: attachments).model
  }
  let(:finished_task) {
    Task.create!(name: 'Hi!', description: 'Done.', user_id: user.id, state: :finished)
  }

  it "should add attachment" do
    updated_task = Task::AddAttachment.(
      task_id: task.id,
      file: FilelessIO.from('image/png', 'digits.png', '123'),
      current_user: user
    ).model
    expect(updated_task.attachments.count).to eq(3)
  end

  it "shouldn't add large attachment" do
    expect{
      Task::AddAttachment.(
        task_id: task.id,
        file: FilelessIO.from('image/png',
                              'digits.png',
                              '1' * (Attachment::MAX_FILE_SIZE + 1)),
        current_user: user
      )
    }.to raise_error(Trailblazer::Operation::InvalidContract)
  end

  it "shouldn't add attachment with unallowed content-type" do
    expect{
      Task::AddAttachment.(
        task_id: task.id,
        file: FilelessIO.from('image/gif',
                              'digits.gif',
                              '123'),
        current_user: user
      )
    }.to raise_error(Trailblazer::Operation::InvalidContract)
  end

  it "shouldn't allow to attach files to other people's tasks" do
    expect{
      Task::AddAttachment.(
        task_id: task.id,
        file: FilelessIO.from('image/png',
                              'digits.png',
                              '123'),
        current_user: another_user
      )
    }.to raise_error(Trailblazer::NotAuthorizedError)
  end

  it "shouldn't allow to attach files to finished tasks" do
    expect{
      Task::AddAttachment.(
        task_id: finished_task.id,
        file: FilelessIO.from('image/png',
                              'digits.png',
                              '123'),
        current_user: user
      )
    }.to raise_error(Trailblazer::NotAuthorizedError)
  end
end