require 'discourse_api'
require 'date'
require 'logger'

# init logger and write to file only if one exist.
# init logger and append to file only if one exit. 
# init logger and create and write to file if one doesn't exist.
file = File.open('app.log', File::WRONLY | File::APPEND | File::CREAT)
logger = Logger.new(file)

# setup
config = DiscourseApi::ExampleHelper.load_yml
client = DiscourseApi::Client.new(config['host'] || '') # forum url 
client.api_key = config['api_key'] || "" # forum API key
client.api_username = config['api_username'] || "" # forum username associated with api key

# get new users from the discourse api and order by date created.
users = client.list_users("new", {:order => "created"})

# container for holding user that will get a message.
newUsers = []

# loop through users returned from API.
# NOTE: we have to loop through all the users becuase I havn't found
# a way to return just the users that were created yesterday from the discourse
# API. 
users.each {  |x| 
    dateCreated = x["created_at"].split("T")[0] # get the date user was created.
    yesterday = Date.today.prev_day.to_s # get yesterdays date.
    
    # if the user was created yesterday
    # add their username to the new user container.
    if(dateCreated == yesterday) 
        newUsers.push(x["username"])
    end
}

# null/empty check on new users container. 
if newUsers.length > 0
  # give the message a title
  title = "Welcome To Our Community!"
  # put all the new users as the recepient of new message.
  user_names = newUsers.join(",")

  # send the message.
  client.create_private_message(                  
    title: "Welcome to the forum!",
    raw: "Hey, I noticed you recently joined the forum so I am dropping by to give you a warm welcome. We are glad to have you and look forward to seeing you around! \n\n Also, We love when new users give an introduction so feel free to create a new topic and introduce yourself! We love stories about how you and your parrot met, pictures of your parrots, your background, what you like to do, etc. Of course, you don't have to do this if you don't want to but we love meeting new users. \n\n One last thing, I am a moderator of the forum so feel free to message me anytime! If you need help posting a topic, uploading a picture, categorizing your posts.... it doesn't matter! I am here to help. \n\n Have a good day! :slight_smile:",
    target_usernames: user_names
  )
  infoMessage = 'A welcome message was sent to ' + newUsers.count.to_s + ' users.'
  logger.info('MESSAGE SENT') { infoMessage } 
  puts infoMessage
else
  infoMessage = 'Program executed succesfully but did not send a message because there were no new users created on ' + Date.today.prev_day.to_s
  logger.info('NO NEW USERS') { infoMessage }
end

# close the logger and write to file. 
logger.close()