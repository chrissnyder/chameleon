## z8e

Translation service for the Zooniverse. Located at [http://z8e.herokuapp.com](http://z8e.herokuapp.com)

### Setup

Ensure you have Node > 0.10.x installed.

    npm install .
    
### Testing

Requires MongoDB to be running.

    npm run-script start

### Deploying

    npm run-script deploy

Note deploying force pushes to Heroku. Probably a bad idea. The account used is billing@zooniverse.org. Ask for the SSH keys from someone who has them.
