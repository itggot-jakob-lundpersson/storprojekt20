require 'sinatra'
require 'slim'
require 'sqlite3'
require 'bcrypt'

#Retrieves specific database
def connect_db(database)
    choice = SQLite3::Database.new("db/#{database}.db")
    return choice
end

#Inserts params from registration-form into users, using BCrypt on password
def register_user(db, username, password)
    result = db.execute("SELECT id FROM users WHERE name=?", username)
    if result.empty?
        password_digest = BCrypt::Password.create(password)
        db.execute("INSERT INTO users(name, password, role) VALUES (?,?,?)", [username, password_digest, "user"])
        
    end
    
    return result
end

#Gets id of user by name
def retrieve_user_id(db, username)
    
    user_id = db.execute("SELECT ID FROM users WHERE name=?", username)
    
    return user_id
end

#Gets password hash of user by name
def retrieve_user_password(db, username)
    password_hash = db.execute("SELECT password FROM users WHERE name=?", username)
    
    return password_hash.first
end

#Gets role of user by id
def retrieve_role(db, user_id)
    result = db.execute("SELECT role FROM users WHERE id=?", user_id)
    
    return result
end

#Verifies stored password against password hash
def password_verification(password_hash, password)
    
    if BCrypt::Password.new(password_hash.first) == password
        verification = true
        
    else
        verification = false
    end
    
    return verification
end

#Verifies that template with specified name does not exist
def template_name_validation(db, template_name)
    exists = db.execute("SELECT name FROM template WHERE name=?", template_name)
    
    if exists==[]
        result = true
        
    else
        result = false
        
        
    end
    
    
    return result
end

#Creates a new template by inserting the relevant information
def create_template(db, template_name, rarity, description, tags, collection, image_link)
    db.execute("INSERT INTO template(name, rarity, description, tag, collection, image) VALUES (?,?,?,?,?,?)", [template_name, rarity, description, tags, collection, image_link])
    
    
end


#Creates a number of cards of specified existing template, updates specified user to own these cards
def create_cards(db, template_name, card_amount, owner)
    old_amount = db.execute("SELECT amount FROM template where name=?", [template_name])
    new_card_amount = card_amount.to_i + old_amount[0][0].to_i
    
    db.execute("UPDATE template SET amount = ? WHERE name = ?", [new_card_amount, template_name])
    
    count = db.execute("SELECT COUNT(*) FROM card")
    card_id = count[0][0].to_i + 1
    this_card_id=[]
    
    i = 0
    history = Time.now.to_s
    while i < card_amount.to_i
        db.execute("INSERT INTO card(template, history) VALUES (?,?)", [template_name, history])
        this_card_id << card_id.to_i + i
        
        i=i+1
    end
    current_cards = db.execute("SELECT cards FROM users WHERE name = ?", [owner])[0]
    new_cards = current_cards + this_card_id
    new_cards = new_cards.join(', ')
    
    db.execute("UPDATE users SET cards = ? WHERE name = ?", [new_cards, owner])
    
end

#Retrieves all from template-table in database
def show_all_cards(db)
    
    return db.execute("SELECT * FROM template")
end

#Retrieves all cards owned by specified user, sorts cards into amounts of respective templates
def show_user_cards(db, username)
    owned_cards = db.execute("SELECT cards FROM users WHERE name=?", username)
    if owned_cards[0][0] != nil
        owned_cards = owned_cards[0][0].split(', ')
    end
    
    
    show_these = []
    i = 0
    while i < owned_cards.length
        current = db.execute("SELECT template FROM card WHERE id=?", owned_cards[i+1])
        
        show_these << current
        i = i + 1
    end
    
    amounter=[]
    b = Hash.new(0)
    
    show_these.each do |v|
        b[v] += 1
    end
    
    b.each do |k, v|
        amounter << "#{v} copies of #{k}"
    end
    p amounter

    owned_templates = show_these.uniq
    
    i = 0
    while i < owned_templates.length
        owned_templates[i] << amounter[i]
        i += 1
    end
    return owned_templates
end

#Inserts relevant information into trade-table, 
def create_trade(db, cards, name, users, expiration)
    
    db.execute("INSERT INTO trades(cards, name, sender, expiration) VALUES (?,?,?,?)", [cards, name, users, expiration])
    user_id = retrieve_user_id(db, users)
    trade_id = db.execute("SELECT max(id) FROM trades")[0][0]
    db.execute("INSERT INTO user_trade_relation(user, trade) VALUES (?,?)", [user_id, trade_id])
end

#Retrieves all trades
def show_all_trades(db)
    return db.execute("SELECT * FROM trades")

end

#Retrieves all trades belonging to user
def show_user_trades(db, username)
    return db.execute("SELECT * FROM trades WHERE sender=?", username) 

end


#Retrieves all offers a specified user has made
def show_user_offers(db, username)
    user_trades = db.execute("SELECT id FROM trades WHERE sender=?", username)
    list = []
    i = 0

    while i < user_trades.length
        current = db.execute("SELECT * FROM offers WHERE reciever=?", user_trades[i])
        if current != []
            list << current
        end

        i += 1
    end
    p list
    return list

end

#Verifies wether user owns any cards
def user_owns_cards(db, username)

    does = false
    if db.execute("SELECT cards FROM users WHERE name=?", username) != nil
        does = true
    end

    return does
end

#Verifies wether user owns trade
def trade_ownership_verified(db, cards, user)
    result = false
    owned_cards = db.execute("SELECT cards FROM users WHERE name=?", user)[0][0]
    owned_cards = owned_cards.split(", ")
    p owned_cards
    selected_cards = cards.split(", ")
    if selected_cards - owned_cards == []
        result = true
    end

    return result
end

#Retrieves trade name by id
def get_trade_name(db, trade_id)
    result = db.execute("SELECT name FROM trades WHERE id=?", trade_id)

    return result
end

#Retrieves all of trade by id
def get_trade(db, trade_id)

    result = db.execute("SELECT * FROM trades WHERE id=?", trade_id)

    return result
end

#Verifies wether user has trades
def has_trades(db, username)
    result = false
    if db.execute("SELECT * FROM trades WHERE sender=?", username) != []
        result = true
    end

    return result

end

#Creates offer by inserting relevant info, connects user to trade by inserting user id into user-trade-relation-table
def join_trade(db, cards, user, reciever_trade)
    user_id = retrieve_user_id(db, user)[0][0]
    db.execute("INSERT INTO offers(cards, sender, reciever) VALUES(?,?,?)", [cards, user, reciever_trade])
    db.execute("INSERT INTO user_trade_relation(user, trade) VALUES (?,?)", [user_id, reciever_trade])

end

#Verifies wether trades have offers
def trades_have_offers(db, trade_id)
    result = false
    p trade_id

    i = 0

    while i < trade_id.length
        if db.execute("SELECT * FROM offers WHERE reciever=?", trade_id[i][2]) != nil
            result = true
        end
        i+=1
    end

    return result
end


#Tranfers cards between users according to specified offer, updates ownership, deletes trade and offers
def accept_offer(db, offer, user)

    offer_cards = db.execute("SELECT cards FROM offers WHERE id=?", offer)[0][0].split(", ")
    offer_sender = db.execute("SELECT sender FROM offers WHERE id=?", offer)[0][0]
    reciever = db.execute("SELECT reciever FROM offers WHERE id=?", offer)[0][0]
    #user_reciever = db.execute("SELECT sender FROM trades WHERE id=?", reciever)[0][0]
    trade_cards = db.execute("SELECT cards FROM trades WHERE id=?", reciever)[0][0]
    trade_cards = trade_cards.to_s.split(", ")
    reciever_cards = db.execute("SELECT cards FROM users WHERE id=?", user)[0][0].to_s.split(", ")
    sender_cards = db.execute("SELECT cards FROM users WHERE name=?", offer_sender)[0][0].to_s.split(", ")

    p offer_cards
    p trade_cards

    sender_cards_update = sender_cards + trade_cards - offer_cards
    reciever_cards_update = reciever_cards + offer_cards - trade_cards

    p sender_cards_update
    p sender_cards_update.join(", ")
    p reciever_cards_update.join(", ")
    p reciever_cards_update

    db.execute("UPDATE users SET cards=? WHERE name=?", [sender_cards_update.join(", "), offer_sender])
    db.execute("UPDATE users SET cards=? WHERE id=?", [reciever_cards_update.join(", "), user])
    db.execute("DELETE FROM offers WHERE id=?", offer)
    db.execute("DELETE FROM trades WHERE id=?", reciever)
    db.execute("DELETE FROM user_trade_relation WHERE trade=?", reciever)

    
end