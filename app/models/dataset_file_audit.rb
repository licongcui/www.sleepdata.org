class DatasetFileAudit < ActiveRecord::Base

  # Model Relationships
  belongs_to :dataset
  belongs_to :user

end
