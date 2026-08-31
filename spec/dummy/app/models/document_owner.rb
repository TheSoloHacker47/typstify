# frozen_string_literal: true

class DocumentOwner < ActiveRecord::Base
  has_many_attached :documents
end
