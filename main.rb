     
require 'sinatra'

require 'sinatra/roader' if development?
# also_reload 'db/data_access' if development?


def run_sql(sql)
  db = PG.connect(ENV['DATABASE_URL'] || {dbname: 'puppylove'})
  result = db.exec(sql)
  db.close
  return result 
end


get '/' do
  erb :index
end





