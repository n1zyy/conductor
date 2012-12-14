#
#   Copyright 2012 Red Hat, Inc.
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

Tim::ProviderImage.class_eval do
  STATUS_NEW       = 'NEW'
  STATUS_PUSHING   = 'PUSHING'
  STATUS_FAILED    = 'FAILED'
  STATUS_COMPLETE  = 'COMPLETE'
  STATUS_IMPORTED  = 'IMPORTED'

  belongs_to :provider_account

  validates_presence_of :provider_account
  validate :valid_external_image_id?, :if => :should_validate_external_image?

  before_create :set_credentials

  scope :complete,    :conditions => { :status => [STATUS_COMPLETE, STATUS_IMPORTED] }

  def self.find_by_images(images)
    Tim::ProviderImage.joins(:target_image => :image_version).
      where(:tim_image_versions => {:base_image_id => [images.map(&:id)]})
  end

  def self.find_by_provider_account_and_image_version(account, version)
    joins(:target_image => :image_version).
      where(:provider_account_id => account.id,
            'tim_image_versions.id' => version.id)
  end

  def self.find_by_provider_account_and_image(account, image)
    joins(:target_image => :image_version).
      where(:tim_image_versions => {:base_image_id => image.id},
            :provider_account_id => account.id)
  end

  def base_image
    target_image.base_image
  end

  def should_validate_external_image?
    imported? && external_image_id.present?
  end

  def valid_external_image_id?
    account = ProviderAccount.find(provider_account_id)
    conn = provider_account.connect

    dc_image = conn.image(external_image_id) rescue nil
    if dc_image.blank?
      errors.add(:external_image_id, I18n.t('tim.base_images.import.not_on_provider'))
      return false
    end

    true
  end

  # This is a misnomer -- a TargetImage is built, and a ProviderImage is pushed.
  def built?
    target_image.built?
  end

  def pushed?
    status == STATUS_COMPLETE || imported?
  end

  private

  def set_credentials
    @credentials = provider_account.to_xml(:with_credentials => true)
  end
end
