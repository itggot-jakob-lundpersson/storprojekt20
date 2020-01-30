require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
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

    password_digest = db.execute("SELECT password FROM users WHERE name=?", username)
    user_id = db.execute("SELECT id FROM users WHERE name=?", username)


    if BCrypt::Password.new(password_digest) == password
        session[:user_id] = user_id
        redirect("users/:user_id")
    else

    end
    

    redirect("users/index")
end

post('/register') do 
    db=SQLite3::Database.new('db/greed.db')
    username = params["r_username"]
    password = params["r_password"]
    
    result = db.execute("SELECT id FROM sers WHERE name=?", username)
    
    if result.empty?
        password_digest = BCrypt::Password.create(password)
        p password_digest
        db.execute("INSERT INTO users(name, password) VALUES (?,?)", [username, password_digest])
        session[:user_id] = db.execute("SELECT ID FROM Users WHERE Name=?", username)
    else
        redirect("/")
    end
    
    redirect("users/:user_id")
end

get('/users/new') do 
    
    slim(:"users/new")
end

get('/users/') do 
    
    slim(:"users/index")
end

get('/users/:user_id') do

    slim(:"users/show")
end