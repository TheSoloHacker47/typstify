# frozen_string_literal: true

require "spec_helper"

require_relative "dummy/config/environment"
require "rspec/rails"

ActiveRecord::Schema.define do
  create_table :document_owners, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :active_storage_blobs, force: true do |t|
    t.string   :key,          null: false
    t.string   :filename,     null: false
    t.string   :content_type
    t.text     :metadata
    t.string   :service_name, null: false
    t.bigint   :byte_size,    null: false
    t.string   :checksum
    t.datetime :created_at, null: false
    t.index [:key], unique: true
  end

  create_table :active_storage_attachments, force: true do |t|
    t.string     :name,     null: false
    t.references :record,   null: false, polymorphic: true, index: false
    t.bigint     :blob_id,  null: false
    t.datetime   :created_at, null: false
    t.index %i[record_type record_id name blob_id], name: "index_asa_uniqueness", unique: true
  end

  create_table :active_storage_variant_records, force: true do |t|
    t.belongs_to :blob, null: false, index: false
    t.string     :variation_digest, null: false
    t.index %i[blob_id variation_digest], name: "index_asvr_uniqueness", unique: true
  end
end

RSpec.configure do |config|
  config.infer_spec_type_from_file_location!
  config.use_transactional_fixtures = false

  # The dummy app's views are the template root for request specs; each spec
  # gets a clean config, so re-point it after the global reset.
  config.before do
    Typstify.configure do |c|
      c.template_root = Rails.root.join("app/views")
      c.strict_fonts = false
    end
  end
end
