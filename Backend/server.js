const express = require('express');
const axios = require('axios');
const cors = require('cors');
const path = require(`path`);
const dotenv = require(`dotenv`);
const moment = require(`moment`);
const mongoose = require(`mongoose`);
const bodyParser= require(`body-parser`);
const ObjectId = require(`mongodb`);

dotenv.config();

// Set up the Express app
const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.static(path.join(__dirname, './dist/frontend/browser'), {
  setHeaders: (res, path, stat) => {
      if (path.endsWith('.js')) {
      res.set('Content-Type', 'application/javascript');
      }
  }
  }));

app.use(cors());
app.use(bodyParser.json());



//app.use(express.static('/STOCK_Attempt2/frontend/dist/frontend'));
// app.use(express.static(path.join(__dirname, '../frontend/dist/frontend')));


// app.set('trust proxy', true);

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

const url = `mongodb+srv://anannyap:4uBZK3Ac1CshPyDe@cluster0.bbmkfbw.mongodb.net/?retryWrites=true&w=majority&appName=Cluster0`;
const db = async () => {
  try {
    await mongoose.connect(url);
    console.log('Connected to MongoDB');
  } catch (error) {
    console.error('Could not connect to MongoDB:', error);
  }
};
db();

// schema for db collection
const wishlistSchema = new mongoose.Schema({
    ticker: String,
    name: String
  });
  const holdingSchema = new mongoose.Schema({
    ticker: String,
    quantity: Number,
    cost: Number
  });

  const moneySchema = new mongoose.Schema({
    money: Number
  });
  
  // Create model from schema
  // const Favorite = mongoose.model('Favorite', favoriteSchema, 'favorites'); 
  const WishlistModel = mongoose.model('Favorite', wishlistSchema, 'favorites');
  const Holding = mongoose.model('Holding', holdingSchema, 'holdings');
  const MoneyModel = mongoose.model('money', moneySchema);

// Set up a route that will send requests to the Finnhub API
app.get('/api/company-profile/', async (req, res) => {
    // Get the ticker symbol from the query string
    const ticker = req.query.ticker;
    const finnhubUrl = `https://finnhub.io/api/v1/stock/profile2?symbol=${ticker}&token=${process.env.FINNHUB_API_KEY}`;
    try {
        // Fetch the company profile from Finnhub using axios
        const response = await axios.get(finnhubUrl);   
        // Send the data back to the client
        res.json(response.data);
    } catch (error) {
        errorCheck(error, res);
    }
});

// Set up a route that will send requests to the Finnhub API
app.get('/api/quote/', async (req, res) => {
    // Get the ticker symbol from the query string
    const ticker = req.query.ticker;
    const finnhubUrl = `https://finnhub.io/api/v1/quote?symbol=${ticker}&token=${process.env.FINNHUB_API_KEY}`;
    try {
        // Fetch the company profile from Finnhub using axios
        const response = await axios.get(finnhubUrl);   
        // Send the data back to the client
        res.json(response.data);
    } catch (error) {
        errorCheck(error, res);
    }
});


// Set up a route that will send requests to the Finnhub API
app.get('/api/autofill/:query', async (req, res) => {
    // Get the ticker symbol from the query string
    const query = req.params.query;
    const finnhubUrl = `https://finnhub.io/api/v1/search?q=${query}&token=${process.env.FINNHUB_API_KEY}`;
    try {
        // Fetch the company profile from Finnhub using axios
        const response = await axios.get(finnhubUrl);   
        // Send the data back to the client
        res.json(response.data);
    } catch (error) {
        errorCheck(error, res);
    }
});


// Set up a route that will send requests to the Finnhub API
app.get('/api/recommendation/', async (req, res) => {
    // Get the ticker symbol from the query string
    const ticker = req.query.ticker;
    const finnhubUrl = `https://finnhub.io/api/v1/stock/recommendation?symbol=${ticker}&token=${process.env.FINNHUB_API_KEY}`;
    try {
        // Fetch the company profile from Finnhub using axios
        const response = await axios.get(finnhubUrl);   
        // Send the data back to the client
        res.json(response.data);
    } catch (error) {
        errorCheck(error, res);
    }
});

// Set up a route that will send requests to the Finnhub API
app.get('/api/sentiment/', async (req, res) => {
    // Get the ticker symbol from the query string
    const ticker = req.query.ticker;
    const finnhubUrl = `https://finnhub.io/api/v1/stock/insider-sentiment?symbol=${ticker}&from=2022-01-01&token=${process.env.FINNHUB_API_KEY}`;
    try {
        // Fetch the company profile from Finnhub using axios
        const response = await axios.get(finnhubUrl);   
        // Send the data back to the client
        res.json(response.data);
    } catch (error) {
        errorCheck(error, res);
    }
});

// Set up a route that will send requests to the Finnhub API
app.get('/api/peers/', async (req, res) => {
    // Get the ticker symbol from the query string
    const ticker = req.query.ticker;
    const finnhubUrl = `https://finnhub.io/api/v1/stock/peers?symbol=${ticker}&token=${process.env.FINNHUB_API_KEY}`;
    try {
        // Fetch the company profile from Finnhub using axios
        const response = await axios.get(finnhubUrl);   
        // Send the data back to the client
        res.json(response.data);
    } catch (error) {
        errorCheck(error, res);
    }
});

app.get('/api/earnings/', async (req, res) => {
    // Get the ticker symbol from the query string
    const ticker = req.query.ticker;
    const finnhubUrl = `https://finnhub.io/api/v1/stock/earnings?symbol=${ticker}&token=${process.env.FINNHUB_API_KEY}`;
    try {
        // Fetch the company profile from Finnhub using axios
        const response = await axios.get(finnhubUrl);   
        // Send the data back to the client
        res.json(response.data);
    } catch (error) {
        errorCheck(error, res);
    }
});

app.get('/api/charts/', async (req, res) => {
    const ticker = req.query.ticker.toUpperCase();
    const multiplier = 1;

    var currentDate = moment().format('YYYY-MM-DD');
    var from_date = moment().subtract(2, 'years').subtract(1, 'days').format('YYYY-MM-DD');

    const polygonURL = `https://api.polygon.io/v2/aggs/ticker/${ticker}/range/${multiplier}/day/${from_date}/${currentDate}?adjusted=true&sort=asc&apiKey=${process.env.POLYGON_API_KEY}`;

    try {
        // Fetch the company profile from Finnhub using axios
        const response = await axios.get(polygonURL);   
        // Send the data back to the client
        res.json(response.data);
    } catch (error) {
        errorCheck(error, res);
    }
});

app.get('/api/hourData/', async (req, res) => {
    const ticker = req.query.ticker.toUpperCase();
    const multiplier = 1;

    var currentDate = moment().format('YYYY-MM-DD');
    var from_date = moment().subtract(5, 'days').format('YYYY-MM-DD');

    const polygonURL = `https://api.polygon.io/v2/aggs/ticker/${ticker}/range/1/hour/${from_date}/${currentDate}?adjusted=true&sort=asc&apiKey=${process.env.POLYGON_API_KEY}`;


    try {
        // Fetch the company profile from Finnhub using axios
        const response = await axios.get(polygonURL);   
        // Send the data back to the client
        res.json(response.data);
    } catch (error) {
        errorCheck(error, res);
    }

});

app.get('/api/news/', async(req, res) => {
    const ticker = req.query.ticker;
    var currentDate = moment().format('YYYY-MM-DD');
    var from_date = moment().subtract(7, 'days').format('YYYY-MM-DD');
    const finnhubUrl = `https://finnhub.io/api/v1/company-news?symbol=${ticker}&from=${from_date}&to=${currentDate}&token=${process.env.FINNHUB_API_KEY}`;
    try {
        // Fetch the company profile from Finnhub using axios
        const response = await axios.get(finnhubUrl);   
        // Send the data back to the client
        res.json(response.data);
    } catch (error) {
        errorCheck(error, res);
    }
});

app.get('/', (req, res) => {
  res.send('Hello from App Engine!');
});


function errorCheck(error, res) {
    if (error.response) {
        res.status(error.response.status).json({ error: error.response.data });
    } else if (error.request) {
        res.status(500).json({ error: "No response received from Finnhub API" });
    } else {
        res.status(500).json({ error: error.message });
    }
}
  
  // get wishlist Items
  app.get('/wishlist', async (req, res) => {
    try {
      const wishlist = await WishlistModel.find();
      res.json(wishlist);
      console.log(wishlist);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  });
  
  // get holding
  app.get('/holdings', async (req, res) => {
    try {
      const holdings = await Holding.find();
      res.json(holdings);
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
  });
  
  app.post('/wishlist', async (req, res) => {
    try {
      let wishlist = await WishlistModel.findOne({ ticker: req.body.ticker})
      if (wishlist) {
        await wishlist.deleteOne();
        res.json({ message: 'Stock from wishlist deleted' });
        return;
      }
    } catch (error) {
      res.status(500).json({ message: error.message });
    }
    const newItem = new WishlistModel({ ticker: req.body.ticker, name: req.body.name});
    try {
      await newItem.save();
      res.status(201).json(newItem);
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  });
  
  // update holding
  app.post('/holdings', async (req, res) => {
    try {
      let holding = await Holding.findOne({ticker: req.body.ticker});
  
      if (holding) {
        // If holding exists, update it
        const newQuantity = holding.quantity + req.body.quantity;
  
        // if new quantity is 0, delete the holding
        if (newQuantity === 0) {
          await holding.deleteOne();
          res.json({ message: 'Holding deleted' });
          return;
        }
  
        const newCost = holding.cost + req.body.cost;
        
        holding.quantity = newQuantity;
        holding.cost = newCost;
        
        await holding.save();
        res.status(200).json(holding);
      } else {
        // If holding does not exist, create a new one
        const newHolding = new Holding({
          ticker: req.body.ticker,
          quantity: req.body.quantity,
          cost: req.body.cost
        });
        await newHolding.save();
        res.status(201).json(newHolding);
      }
    } catch (error) {
      res.status(400).json({ message: error.message });
    }
  });

  app.get('/money', (req, res) => {
    MoneyModel.find()
      .then((result) => {
        res.status(200).json(result);
      })
      .catch((err) => {
        console.error(err);
        res.status(500).json(err);
      });
  });
  
  app.post('/money', (req, res) => {
    MoneyModel.deleteOne({})
      .then(() => {
        const money = new MoneyModel(req.body);
  
        money.save()
          .then((result) => {
            console.log(result);
            res.status(200).json(result);
          })
          .catch((err) => {
            console.log(err);
            res.status(500).json(err);
          });
      })
    });
  


  app.get('*', (req, res) => {
    res.sendFile(path.join(__dirname, './dist/frontend/browser/index.html'));
    });

