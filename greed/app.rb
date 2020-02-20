require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
enable :sessions

get('/') do 
    
    slim(:index)
end

post('/login') do 
    db=SQLite3::Database.new('db/greed.db')
    username = params["l_username"]
    password = params["l_password"]
    
    check = db.execute("SELECT password, id FROM users WHERE name=?", username)
    
    if check.empty?
        redirect("/")
    end

    password_digest = check[0][0] #db.execute("SELECT password FROM users WHERE name=?", username)
    p password_digest
    user_id = db.execute("SELECT id FROM users WHERE name=?", username)
    

    if BCrypt::Password.new(password_digest) == password
        session[:user_id] = user_id[0][0]
        session[:username] = username
        redirect("/users/#{session[:username]}")
    else
        
    end
    

    redirect("users/index")
end

post('/register') do 
    db=SQLite3::Database.new('db/greed.db')
    username = params["r_username"]
    password = params["r_password"]
    
    result = db.execute("SELECT id FROM users WHERE name=?", username)
    
    if result.empty?
        password_digest = BCrypt::Password.create(password)
        p password_digest
        db.execute("INSERT INTO users(name, password, role) VALUES (?,?,?)", [username, password_digest, "user"])
        session[:user_id] = db.execute("SELECT ID FROM users WHERE name=?", username)[0][0]
        session[:username] = username
    else
        redirect("/")
    end
    
    redirect("/users/#{session[:username]}")
end

get('/users/new') do 
    
    slim(:"users/new")
end



get('/users/:username') do
    result = "db.execute"

    slim(:"users/show", locals:{info:result})
end

get('/users/') do 

    
    slim(:"users/index")
end

get('/cards/') do 

    
    slim(:"users/index")
end