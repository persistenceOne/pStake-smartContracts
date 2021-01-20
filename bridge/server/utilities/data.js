const MongoClient = require('mongodb').MongoClient;
const errors = require('./errors');
const config = require('../config.json');

const mongoURL = config.dbURL + config.dbName;
let dbo;    //Not to export.

function SetupDB(callback) {
    MongoClient.connect(mongoURL, {useUnifiedTopology: true})
        .then((db, err) => {
            if (err) throw  err;
            dbo = db.db(config.dbName);
            callback();
        })
        .catch(err => errors.exitProcess(err));
}

async function SetupDBSync(callback) {
    let db = await MongoClient.connect(mongoURL, {useUnifiedTopology: true})
    dbo = db.db(config.dbName);
    callback();
    return dbo;
}

function find(collection, query, options = {}) {
    return dbo.collection(collection).find(query, options).toArray();
}

function findSorted(collection, query, sortingOption, options = {}) {
    return dbo.collection(collection).find(query, options).sort(sortingOption).toArray();
}

function insertOne(collection, data) {
    return dbo.collection(collection).insertOne(data);
}

function insertMany(collection, data) {
    return dbo.collection(collection).insertMany(data);
}

function updateOne(collection, query, data) {
    return dbo.collection(collection).updateOne(query, {$set: data});
}

function deleteOne(collection, query) {
    return dbo.collection(collection).deleteOne(query);
}

function deleteMany(collection, query) {
    return dbo.collection(collection).deleteMany(query);
}

function upsertOne(collection, query, data) {
    return dbo.collection(collection).updateOne(query, {$set: data}, {upsert: true});
}

module.exports = {
    SetupDB,
    SetupDBSync,
    find,
    findSorted,
    insertOne,
    insertMany,
    updateOne,
    deleteOne,
    deleteMany,
    upsertOne
};
