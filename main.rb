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

def redirect_if_not_authenticated
  if ! logged_in? 
    redirect '/'
  end
end

def run_sql(sql, params=[])
  db = PG.connect(ENV['DATABASE_URL'] || {dbname: 'puppylove'})
  results = db.exec_params(sql, params)
  db.close
  return results
end

get '/' do
  erb :index, layout: false
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

  results_users = run_sql("INSERT INTO dogs(username, image_url, age,gender, breed, bio, loc_suburb,loc_state,loc_country, user_id) VALUES('#{params['name']}', '#{params['image_url']}', '#{params['age']}', '#{params['gender'].downcase.capitalize}', '#{params['breed']}', '#{params['bio']}', '#{params['loc_suburb']}','#{params['loc_state']}','#{params['loc_country']}','#{user['id']}');")
  
  redirect '/'
end

#dog profile
get '/dogs/:id' do
  redirect_if_not_authenticated
  results = run_sql("SELECT * FROM dogs WHERE id = #{params['id']};")
  current_dog = find_dog_by_user_id(current_user["id"])
  
  erb :profile, locals: {
    current_user_id: current_user["id"],
    current_dog_id: current_dog["id"],
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
    erb :index
  end
end

delete '/logout' do
  redirect_if_not_authenticated
  #destroy this session
  session[:user_id] = nil
  redirect '/'
end


#edit form
get '/dogs/:id/edit' do 
  redirect_if_not_authenticated
  results = find_dog_by_id(params['id'])
  
  erb :edit, locals: {
    dog: results
  }
end

# messages/new msg form
get '/dogs/:recipient_id/messages' do
  redirect_if_not_authenticated
  current_dog = find_dog_by_user_id(current_user["id"])
  recipient_dog = find_dog_by_id("#{params["recipient_id"]}")

  sql = "SELECT * FROM messages, dogs
  WHERE ((sender_id=#{current_dog["id"]}
  AND recipient_id=#{recipient_dog["id"]})
  OR (sender_id=#{recipient_dog["id"]}
  AND recipient_id=#{current_dog["id"]}))
  AND sender_id=dogs.id
  ORDER BY created_at DESC;
  "

  results = run_sql(sql)

  erb :messages, locals: {
  current_dog: current_dog,
  recipient_dog: recipient_dog,
  messages: results
  }

end

get '/my_messages' do
  redirect_if_not_authenticated
  # Select recipients data
  # sender is you
  current_dog = find_dog_by_user_id(session[:user_id])
  sql_sender = "SELECT DISTINCT username, dogs.id as dog_id, image_url
    FROM messages, dogs 
    WHERE sender_id=#{current_dog['id']} 
    AND recipient_id=dogs.id;"
  # Select senders data
  # recipients is you
  sql_recipient = "SELECT DISTINCT username, dogs.id as dog_id, image_url
    FROM messages, dogs 
    WHERE recipient_id=#{current_dog['id']} 
    AND sender_id=dogs.id;"
  # merge distinct and sort by time desc
  result_sender = run_sql(sql_sender)
  result_recipient = run_sql(sql_recipient)

  result = result_sender.to_a.concat(result_recipient.to_a)
  unique_results = result.to_a.uniq! {|result| result['dog_id'] }

  erb :my_messages, locals:{
    results: unique_results
  }
end

#actual creating msg
post '/new_message' do
  redirect_if_not_authenticated
  sql = "INSERT INTO messages (sender_id, recipient_id, created_at, message_content) VALUES ('#{params['sender_id']}','#{params['recipient_id']}', '#{Time.now}' ,'#{params['message_content']}');"

  results = run_sql(sql)

  redirect "/dogs/#{params['recipient_id']}/messages"
end



#actual edit
patch '/dogs/:id' do 
  redirect_if_not_authenticated
  sql = "UPDATE dogs SET username='#{params['name']}', image_url='#{params['image_url']}', age='#{params['age']}', gender='#{params['gender']}', breed='#{params['breed']}', bio='#{params['bio']}', loc_suburb='#{params['loc_suburb']}', loc_state='#{params['loc_state']}', loc_country='#{params['loc_country']}' WHERE id = '#{params['id']}';"

  run_sql(sql)

  redirect "/dogs/#{params['id']}"
end 

get '/search' do
  erb :search
end

get '/search_results' do

  if params['gender'].downcase.capitalize == "Female"
    sql = "SELECT * FROM dogs 
    WHERE username ILIKE '%#{params['name']}%'
    AND age ILIKE '%#{params['age']}%'
    AND gender = 'Female'
    AND breed ILIKE '%#{params['breed']}%'
    AND bio ILIKE '%#{params['keywords']}%'
    AND (loc_suburb ILIKE '%#{params['location']}%'
    OR loc_state ILIKE '%#{params['location']}%'
    OR loc_country ILIKE '%#{params['location']}%')
    ;"

  elsif params['gender'].downcase.capitalize == "Male"
    sql = "SELECT * FROM dogs 
    WHERE username ILIKE '%#{params['name']}%'
    AND age ILIKE '%#{params['age']}%'
    AND gender = 'Male'
    AND breed ILIKE '%#{params['breed']}%'
    AND bio ILIKE '%#{params['keywords']}%'
    AND (loc_suburb ILIKE '%#{params['location']}%'
    OR loc_state ILIKE '%#{params['location']}%'
    OR loc_country ILIKE '%#{params['location']}%')
    ;"
  
  else  
    sql = "SELECT * FROM dogs 
    WHERE username ILIKE '%#{params['name']}%'
    AND age ILIKE '%#{params['age']}%'
    AND breed ILIKE '%#{params['breed']}%'
    AND bio ILIKE '%#{params['keywords']}%'
    AND (loc_suburb ILIKE '%#{params['location']}%'
    OR loc_state ILIKE '%#{params['location']}%'
    OR loc_country ILIKE '%#{params['location']}%')
    ;"

  end

  results = run_sql(sql)

  erb :search_results, locals: {
    dogs: results,
    user_id: current_user["id"]
  }

end

#delete account
delete '/dogs/:id' do 
  delete_messages = "DELETE FROM messages WHERE sender_id = #{params['id']} OR recipient_id=#{params['id']};"
  run_sql(delete_messages)
  delete_dog = "DELETE FROM dogs WHERE id = #{params['id']};"
  run_sql(delete_dog)
  delete_user = "DELETE FROM users WHERE id = #{session[:user_id]};"
  run_sql(delete_user)
  session[:user_id] = nil
  redirect '/'
end