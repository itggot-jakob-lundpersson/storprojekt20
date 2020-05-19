require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require_relative './model.rb'
enable :sessions

#Display landing page
get('/') do 
    
    slim(:index)
end

#Login user
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

#Register user
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

#Display registration form
get('/users/new') do 
    
    slim(:"users/new")
end


#Display user page
get('/users/:username') do
    result = "db.execute"
    
    slim(:"users/show") #, locals:{info:result}
end

#Display login form
get('/login') do 
    
    
    slim(:"login")
end

#Display page showing all cards
get('/cards/') do
    db = connect_db("greed")


    session[:cards] = show_all_cards(db)
    if user_owns_cards(db, session[:username])
        session[:your_cards] = show_user_cards(db, session[:username])
    end
    
    
    slim(:"cards/index")
end

#Display card-creation form
get('/cards/new') do 
    
    
    slim(:"cards/new")
end

#Display all trades
get('/trades/') do 
    db = connect_db("greed")
    session[:trades] = show_all_trades(db)
    if has_trades(db, session[:username])
        session[:user_trades] = show_user_trades(db, session[:username])
        if trades_have_offers(db, session[:user_trades])
            p "have offers"
            session[:user_offers] = show_user_offers(db, session[:username])
        end
    else 
        session[:user_trades] = []
    end
    slim(:"trades/index")
end

#Display trade creation form
get('/trades/new') do 
    
    
    slim(:"trades/new")
end

#Display specific trade
get('/trades/:show_trade') do


    slim(:"trades/show")
end

#Retrieves specific trade, redirect to 'trades/[:show_trade]'
post('/show_trade') do
    db = connect_db("greed")
    show_trade_id = params["show_trade_id"]

    session[:show_trade] = get_trade_name(db, show_trade_id)[0][0]
    session[:specific_trade] = get_trade(db, show_trade_id)[0]
    

    redirect("trades/#{session[:show_trade]}")
end

#Create trade, redirect to 'trades/new'
post('/create_trade') do
    db = connect_db("greed")

    cards = params["card_id"]
    name = params["trade_name"]
    expiration = params["expiration"]
    users = session[:username]
    if trade_ownership_verified(db, cards, users)
        create_trade(db, cards, name, users, expiration)
    end
    
    redirect('/trades/new')
end

#Send offer to trade, redirect to '/trades/'
post('/join_trade') do
    db = connect_db("greed")

    cards = params["card_id"]
    users = session[:username]
    reciever = session[:specific_trade][2]
    if trade_ownership_verified(db, cards, users)
        join_trade(db, cards, users, reciever)
    end
    
    redirect('/trades/')
end

#Accept an offer, redirect to '/trades/'
post('/accept_offer') do
    db = connect_db("greed")

    offer_id = params["offer_id"]
    user = session[:user_id]
    accept_offer(db, offer_id, user)
    session[:user_offers] = show_user_offers(db, session[:username])

    redirect('/trades/')
end

#Create new template, redirect to '/users/[:username]'
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

#Create new cards, redirect to '/cards/new'
post('/create_cards') do
    db = connect_db("greed")
    name = params["card_name"]
    card_amount = params["card_amount"]
    owner = params["owner"]

    if template_name_validation(db, name) == false
        create_cards(db, name, card_amount, owner)
        

    end


    redirect('/cards/new')
end
