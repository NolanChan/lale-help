class User::Create < ::Form
  attribute :user,     :model, new_records: true, primary: true, default: proc{ User.new }
  attribute :identity, :model, new_records: true, class: User::Identity, default: proc{ user.build_identity}

  attribute :first_name,        :string
  attribute :last_name,         :string
  attribute :email,             :string, matches: /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i

  attribute :password,              :string
  attribute :password_confirmation, :string

  attribute :mobile_phone, :string, required: false
  attribute :home_phone, :string, required: false

  attribute :street_address_1,  :string, required: false
  attribute :city,              :string, required: false
  attribute :state_province,    :string, required: false
  attribute :postal_code,       :string, required: false
  attribute :country,           :string, required: false
  attribute :language, :integer

  attribute :public_profile, :boolean, default: proc { true }
  attribute :accept_terms, :boolean, default: proc { false }

  attribute :circle, :model, required: false

  def language_options
    User.languages.map do |key, val|
      [ I18n.t("language.#{key}"), val ]
    end
  end

  def email
    (@email || user.email || '').downcase
  end

  class Submit < ::Form::Submit
    def validate
      add_error(:password, :does_not_match) if password != password_confirmation
      add_error(:password, :too_short)      if password && password.length < 8
      add_error(:password, :no_upper)       if password && /[[:upper:]]/.match(password).nil?
      add_error(:password, :no_lower)       if password && /[[:lower:]]/.match(password).nil?
      add_error(:password, :no_numeric)     if password && /[[:digit:]]/.match(password).nil?

      add_error(:email, :taken) if User::Identity.where(email: email).exists?
      add_error(:accept_terms, :false) unless accept_terms == true
    end

    def execute
      user.assign_attributes(user_attributes)
      user.identity.assign_attributes(inputs.slice(:email, :password))
      user.address = Address.new(inputs.slice(:street_address_1, :city, :state_province, :postal_code, :country))

      user.save
      user.identity.save

      Circle::Join.run(user: user, circle_id: circle.id) if circle.present?

      user
    end

    private

    def user_attributes
      inputs.slice(:first_name, :last_name, :mobile_phone, :home_phone, :language,
        :public_profile, :accept_terms
      )
    end

  end
end
