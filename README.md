## http.rb resubmits body after unsafe redirect

This repo contains my efforts to debug an error raised from http.rb once post request bodies exceed \~2-3 megabytes in size.

## Explanation

The problem is that when [http.rb](https://github.com/httprb/http) is told to follow redirects after a post request, it follows the redirect by issuing an [HTTP GET request with a body](https://stackoverflow.com/questions/978061/http-get-with-request-body#983458) to the provided `Location`.

The server we are talking to then closes the connection too early, probably because it realizes it has received all the headers and that it does not care what the body of the request contains.

## Reproducing the problem

### Get started

This repo uses an rbenv gemset and .ruby-version file. I recommend you use these:

```bash
$ rbenv install
$ rbenv gemset active
```

By default the script is pointed at localhost:4567, which should be your local sinatra server. Open two terminal windows:

```bash
# term1
$ ruby sinatra.rb
# term2
$ ruby main.rb
```

### Dependencies

When running the scripts, bundler/inline will be used to install the required gems

You can find the gems installed when running `main.rb` by looking into `gemfile.rb`.

`sinatra.rb` installs the sinatra gem when you first run it. You can find this at the top of the file.

### Config/Options

If you would like to tweak the number of requests fired, their content etc you can do this by modifying the constants in `main.rb`

### Running the script

When you run the `main.rb` script against the sinatra server in `sinatra.rb`, the different requesters should get tested.

You should see output saying that the HTTPRequester (which uses http.rb) failed the test w/ {manual_redirect: false}.
Go check out the code in `http_requester.rb` to see the difference.

## The Sinatra instance

The test is defined in `setup.rb`. It involves extracting csrf/cookie from the response to GET /, using it to POST some data to /, and following the redirect with a GET to `/redirectmehere`.
The server will respond with errors if the csrf/cookie is incorrect or if the GET request to `/redirectmehere` contains a request body with size > 0, thereby failing the test.

The sinatra app thus *simulates* the problem, but does not cause the same exception. You may point `main.rb` at http://vefa.fakturabank.no by commenting in the VALIDATOR_URL constant in `main.rb` to cause the real problem.

The sinatra server echoes http headers and body for you to inspect manually, in case something goes wrong.

## For the curious

If you're curious, the server we are automating against is a Validator for the EHF Invoicing format. We send xml files to it and get some errors back. They do not want us validating against the official instance, which is why we run our own. You can read more about the standard [here](https://peppol.eu/peppol-bis-billing-3-0/) or by searching for 'PEPPOL BIS Billing 3.0' or 'EHF 3'.

Don't look in `socket_requester.rb`
