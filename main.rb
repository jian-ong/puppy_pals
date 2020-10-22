require 'sinatra'
require 'pg'
require 'sinatra/reloader' if development?
# also_reload 'db/data_access' if development?
require 'bcrypt'

enable :sessions

def find_user_by_email (email)
  results = run_sql("select * from users where email = $1;",[email])
  return results[0]
end

def find_user_by_id (id)
  results = run_sql("select * from users where id = $1;",[id])
  return results[0]
end

def find_dog_by_user_id(user_id)
  results = run_sql("select * from dogs where user_id = $1;",[user_id])
  return results[0]
end

def find_dog_by_id (id)
  results = run_sql("select * from dogs where id = $1;", [id])
  return results[0]
end

def current_user()
  find_user_by_id(session[:user_id])
end


def logged_in?
  if session[:user_id]
    true
  else
    false
  end
end

def run_sql(sql, params=[])
  db = PG.connect(ENV['DATABASE_URL'] || {dbname: 'puppylove'})
  results = db.exec_params(sql, params)
  db.close
  return results
end

get '/' do
  erb :index
end

#sign up form
get '/dogs/new' do
  erb :new_account
end 


#actual sign up process
post "/signed_up" do

  #check if user exists in users table
  user_check = run_sql("SELECT * FROM users where email = '#{params['email']}';")

  #if not, create user
  if user_check.num_tuples == 0 
    password_digest = BCrypt::Password.create(params['password']);
    results_users = run_sql("INSERT INTO users(email, password_digest) VALUES('#{params['email']}', '#{password_digest}');")

  else 
    erb :duplicate_error
  end

  # insert into dogs
  user = find_user_by_email(params['email'])

  results_users = run_sql("INSERT INTO dogs(username, image_url, age,gender, breed, bio, loc_suburb,loc_state,loc_country, user_id) VALUES('#{params['name']}', '#{params['image_url']}', '#{params['age']}', '#{params['gender']}', '#{params['breed']}', '#{params['bio']}', '#{params['loc_suburb']}','#{params['loc_state']}','#{params['loc_country']}','#{user['id']}');")
  
  redirect '/'
end

#dog profile
get '/dogs/:id' do
  results = run_sql("SELECT * FROM dogs WHERE id = #{params['id']};")
  
  erb :profile, locals: {
    user_id: current_user["id"],
    dog_id: results[0]["id"],
    dog_owner_id: results[0]["user_id"],
    name: results[0]["username"],
    image_url: results[0]["image_url"],
    age: results[0]["age"],
    gender: results[0]["gender"],
    breed: results[0]["breed"],
    bio: results[0]["bio"],
    loc_suburb: results[0]["loc_suburb"],
    loc_state: results[0]["loc_state"],
    loc_country: results[0]["loc_country"]
  }
end


post '/login' do
  
  user = find_user_by_email(params["email"])
  
  if BCrypt::Password.new(user['password_digest']) == (params['password'])
    session[:user_id] = user['id']

    dog = find_dog_by_user_id(user['id'])
    redirect "/dogs/#{dog['id']}"
  else 
    erb :login
  end
end

delete '/logout' do
  #destroy this session
  session[:user_id] = nil
  redirect '/'
end

get '/dogs/:id/edit' do 
  results = find_dog_by_id(params['id'])

  erb :edit, locals: {
    dog: results
  }
end

patch '/dogs/:id' do 
  sql = "UPDATE dogs SET username='#{params['name']}', image_url='#{params['image_url']}', age='#{params['age']}', gender='#{params['gender']}', breed='#{params['breed']}', bio='#{params['bio']}', loc_suburb='#{params['loc_suburb']}', loc_state='#{params['loc_state']}', loc_country='#{params['loc_country']}' WHERE id = '#{params['id']}';"

  run_sql(sql)

  redirect "/dogs/#{params['id']}"
end 