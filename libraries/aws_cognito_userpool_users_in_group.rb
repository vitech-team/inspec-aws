require "aws_backend"

class AWSCognitoUserPoolUsersInGroup < AwsResourceBase
  name "aws_cognito_userpool_users_in_group"
  desc "Client method for returning the list of users with metadata of the specified user pool group."
  example <<-EXAMPLE
    describe aws_cognito_userpool_users_in_group(user_pool_id: 'USER_POOL_ID', group_name: 'GROUP_NAME') do
      its('count') { should eq 3 }
    end
  EXAMPLE

  attr_reader :table

  FilterTable.create
             .register_column(:usernames,                 field: :username)
             .register_column(:user_statuses,             field: :user_status)
             .register_column(:enabled,                   field: :enabled)
             .register_column(:attributes,                field: :attributes)
             .register_column(:mfa_options,               field: :mfa_options)
             .register_column(:user_create_dates,         field: :user_create_date)
             .register_column(:user_last_modified_dates,  field: :user_last_modified_date)
             .register_column(:subs,                      field: :sub)
             .register_column(:emails,                    field: :email)
             .register_column(:email_verified,            field: :email_verified)
             .register_column(:users,                     field: :user)
             .install_filter_methods_on_resource(self, :table)

  def initialize(opts = {})
    super(opts)
    validate_parameters(required: %i(user_pool_id group_name))
    @query_params = {}
    @query_params[:user_pool_id] = opts[:user_pool_id]
    @query_params[:group_name] = opts[:group_name]
    if opts.key?(:user_pool_id)
      raise ArgumentError, "#{@__resource_name__}: user_pool_id must be provided" unless opts[:user_pool_id] && !opts[:user_pool_id].empty?
      @query_params[:user_pool_id] = opts[:user_pool_id]
    end
    if opts.key?(:group_name)
      raise ArgumentError, "#{@__resource_name__}: group_name must be provided" unless opts[:group_name] && !opts[:group_name].empty?
      @query_params[:group_name] = opts[:group_name]
    end
    @table = fetch_data
  end

  def fetch_data
    table_rows = []
    @query_params[:limit] = 60

    loop do
      catch_aws_errors do
        @api_response = @aws.cognitoidentityprovider_client.list_users_in_group(@query_params)
      end
      return table_rows if !@api_response || @api_response.empty?
      @api_response.users.each do |res|
        user_data = res

        table_rows += [{
                         username: res.username,
                         user_status: res.user_status,
                         enabled: res.enabled,
                         attributes: res.attributes,
                         mfa_options: res.mfa_options,
                         user_create_date: res.user_create_date,
                         user_last_modified_date: res.user_last_modified_date,
                         sub: res.attributes.find { |attr| attr.name == 'sub' }.value,
                         email: res.attributes.find { |attr| attr.name == 'email' }.value,
                         email_verified: res.attributes.find { |attr| attr.name == 'email_verified' }.value,
                         user: user_data
                       }]
      end
      break unless @api_response.next_token
      @query_params[:next_token] = @api_response.next_token
    end
    table_rows
  end
end