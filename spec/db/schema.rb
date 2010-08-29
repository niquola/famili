ActiveRecord::Schema.define(:version => 0) do
  create_table :users do |t|
    t.string   :last_name,                 :limit => 25
    t.string   :first_name,                :limit => 25
    t.string   :middle_name,               :limit => 25
    t.string   :name,                      :limit => 25
    t.string   :login,                     :limit => 100
    t.string   :email,                     :limit => 100
    t.string   :number,                    :limit => 100
    t.string   :crypted_password,          :limit => 40
    t.string   :salt,                      :limit => 40
    t.datetime :last_login_datetime
    t.datetime :deleted_at
    t.timestamps
  end

  create_table :articles do |t|
    t.integer   :user_id
    t.string    :title,                :limit => 25
    t.text      :content
    t.timestamps
  end
end
