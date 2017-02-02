async = require "async"
fastCsv = require "fast-csv"
fs = require 'fs'
request = require 'request'
c=0
contacts = []
contactBatches = []

APIKey = "INSERT_API_KEY" #Update API Key per AP Instance
headers = {'autopilotapikey': APIKey, 'Content-Type':'application/json'}
batch = 100
simRequests = 10   #Batches to run simultaneosly, max value 20

stream = fs.createReadStream("./country.csv")

fastCsv
	.fromStream(stream)
	.validate( (data, next)->
		contacts.push contactMaker(data)
		next()
	).on("data", (data)->
		console.log(data)
	).on("end", ->
		while contacts.length > 0
			contactBatches.push(get100Contacts())
		#sendContacts(get100Contacts())
		sendAllBatches()
		#console.log "end", JSON.stringify(contactBatches, null, 2)
	)

#Update Contact Maker, map Autopilot fields to spreadsheet columns
#Example Data File = example.csv
#Follow example JSON on http://docs.autopilot.apiary.io/#reference/api-methods/addupdate-contact/add-or-update-contact
contactMaker = (data)->
	#console.log data
	#process.exit 0
	{	
		Email: data[2],
		FirstName: data[0],
		LastName: data[1],
		MailingCity: data[3],
		MailingState: data[4],
		Company: data[5],
		MailingCountry: data[2],
		NumberOfEmployees: data[6],
		custom:
			'string--Tier': data[7],
			'date--Trial--Start': data[8]

	}

sendContacts = (arrayOfContacts, cb)->
	#todo logic
	console.log arrayOfContacts.length
	opts =
		url: "https://api2.autopilothq.com/v1/contacts", 
		method: 'POST',
		headers: headers,
		body: JSON.stringify(contacts: arrayOfContacts)

	request opts, (err, response, body)->
		#console.log error if error
		console.log "done with batch number", ++c
		return cb err if err
		unless response.statusCode < 299 && response.statusCode
			err = Error "unexpected status code #{resp.statusCode}"
			console.log "response.body", response.body
			return cb err
		return cb null


get100Contacts = ()->
	contacts.splice(0, batch) 

sendAllBatches = ()->
	async.eachLimit(contactBatches, simRequests, sendContacts, (err)->
		console.log "all done", err
	)