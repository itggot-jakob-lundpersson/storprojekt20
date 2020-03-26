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
    db = connect_db("greed")
    username = params["l_username"]
    password = params["l_password"]
    
    if username!="" && password!=""
        check = retrieve_user_id(db, username).first
        
        
        password_hash = retrieve_user_password(db, username)
        user_id = check
        
        
        if password_verification(password_hash, password)
            session[:user_id] = user_id.first
            session[:username] = username
            session[:role] = retrieve_role(db, session[:user_id])[0][0]
            redirect("/users/#{session[:username]}")
        else
            redirect("/")
        end
    end
    
    redirect("/")
end

post('/register') do 
    db=connect_db("greed")
    username = params["r_username"]
    password = params["r_password"]
    
    result = register_user(db, username, password)
    
    if result.empty?
        session[:user_id] = retrieve_user_id(db, username)
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
    
    slim(:"users/show") #, locals:{info:result}
end

get('/login') do 
    
    
    slim(:"login")
end

get('/cards/') do
    db = connect_db("greed")
    if session[:role] == "admin"
        
        
    else 
        
        
    end
    
    slim(:"cards/index")
end

get('/cards/new') do 
    
    
    slim(:"cards/new")
end


get('/trades/') do 
    
    
    slim(:"trades/index")
end

post('/create_template') do
    db = connect_db("greed")
    
    name = params["template_name"]
    rarity = params["rarity"]
    description = params["description"]
    tags = params["tags"]
    collection = params["collection"]
    image = params["image_link"]
    
    if template_name_validation(db, name)
        create_template(db, name, rarity, description, tags, collection, image)
        
        
        redirect('/cards/new')
    else
        

        
        redirect("/users/#{session[:username]}")
    end
    
end

post('/create_cards') do
    db = connect_db("greed")
    name = params["card_name"]
    card_amount = params["card_amount"]

    if template_name_validation(db, name) == false
        create_cards(db, name, card_amount)


    end


    redirect('/cards/new')
end
