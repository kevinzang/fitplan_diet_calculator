class AddAttachmentProfilePicToUserProfiles < ActiveRecord::Migration
  def self.up
    change_table :user_profiles do |t|
      t.attachment :profile_pic
    end
  end

  def self.down
    drop_attached_file :user_profiles, :profile_pic
  end
end
