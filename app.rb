# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"    
require "geocoder"                                                                  #
require "twilio-ruby"                                                                 #
require "bcrypt"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

account_sid = ENV["TWILIO_ACCOUNT_SID"]
auth_token = ENV["TWILIO_AUTH_TOKEN"]

client = Twilio::REST::Client.new(account_sid, auth_token)

ascs_table = DB.from(:ascs)
ratings_table = DB.from(:ratings)
users_table = DB.from(:users)

before do
     @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

    # #enter parameters and get latlong
    # @results = Geocoder.search(params["q"])
    # @location = params["q"]
    # pp @ results

# homepage and list of ascs (aka "index")
get "/" do
    puts "params: #{params}"

    @ascs = ascs_table.all.to_a
    pp @ascs

    view "ascs"
end

# asc details (aka "show")
get "/ascs/:id" do
    puts "params: #{params}"

    @users_table = users_table
    @asc = ascs_table.where(id: params[:id]).to_a[0]
    pp @asc

    @ratings = ratings_table.where(asc_id: @asc[:id]).to_a
    @rating_count = ratings_table.where(asc_id: @asc[:id]).count
    # @rating_average = ratings_table.where(asc_id: @asc[:id], @ratings).average

    view "asc"
end

# display the rating form (aka "new")
get "/ascs/:id/ratings/new" do
    puts "params: #{params}"

    @asc = ascs_table.where(id: params[:id]).to_a[0]
    view "new_rating"
end

# receive the submitted rating form (aka "create")
post "/ascs/:id/ratings/create" do
    puts "params: #{params}"

    # first find the asc that we are rating for
    @asc = ascs_table.where(id: params[:id]).to_a[0]
    # next we want to insert a row in the ratings table with the rating form data
    ratings_table.insert(
        asc_id: @asc[:id],
        user_id: session["user_id"],
        comments: params["comments"],
        rating: params[:rating]
    )

    redirect "/ascs/#{@asc[:id]}"
end

# display the rating form (aka "edit")
get "/ratings/:id/edit" do
    puts "params: #{params}"

    @rating = ratings_table.where(id: params["id"]).to_a[0]
    @asc = ascs_table.where(id: @rating[:asc_id]).to_a[0]
    view "edit_rating"
end

# receive the submitted rating form (aka "update")
post "/ratings/:id/update" do
    puts "params: #{params}"

    # find the rating to update
    @rating = ratings_table.where(id: params["id"]).to_a[0]
    # find the rating's asc
    @asc = ascs_table.where(id: @rating[:asc_id]).to_a[0]

    if @current_user && @current_user[:id] == @rating[:id]
        ratings_table.where(id: params["id"]).update(
            rating: params[:rating],
            comments: params["comments"]
        )

        redirect "/ascs/#{@asc[:id]}"
    else
        view "error"
    end
end

# display the signup form (aka "new")
get "/users/new" do
    view "new_user"
end

# receive the submitted signup form (aka "create")
post "/users/create" do
    puts "params: #{params}"

    # if there's already a user with this email, skip!
    existing_user = users_table.where(email: params["email"]).to_a[0]
    if existing_user
        view "error"
    else
        users_table.insert(
            name: params["name"],
            email: params["email"],
            phone_number: params["phone_number"],
            password: BCrypt::Password.create(params["password"])
        )
            client.messages.create(
            from: "+14243257958", 
            to: "+12017230422",
            body: "Admin Notification: A new account has been created on ASC ratings"
            )
        redirect "/logins/new"
    end
end

# display the login form (aka "new")
get "/logins/new" do
    view "new_login"
end

# receive the submitted login form (aka "create")
post "/logins/create" do
    puts "params: #{params}"

    # step 1: user with the params["email"] ?
    @user = users_table.where(email: params["email"]).to_a[0]

    if @user
        # step 2: if @user, does the encrypted password match?
        if BCrypt::Password.new(@user[:password]) == params["password"]
            # set encrypted cookie for logged in user
            session["user_id"] = @user[:id]
            redirect "/"
        else
            view "create_login_failed"
        end
    else
        view "create_login_failed"
    end
end

# logout user
get "/logout" do
    # remove encrypted cookie for logged out user
    session["user_id"] = nil
    redirect "/logins/new"
end


