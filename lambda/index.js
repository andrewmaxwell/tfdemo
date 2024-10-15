const {DynamoDBClient} = require('@aws-sdk/client-dynamodb');
const {
  GetCommand,
  PutCommand,
  UpdateCommand,
} = require('@aws-sdk/lib-dynamodb');

const tableName = process.env.DYNAMODB_TABLE;

const dynamoDb = new DynamoDBClient();

const getCounterExists = async () => {
  try {
    const data = await dynamoDb.send(
      new GetCommand({TableName: tableName, Key: {id: 'clicks'}})
    );
    const counterExists = !!data.Item;
    console.log('Counter exists:', counterExists);
    return counterExists;
  } catch (error) {
    console.error('Error checking if counter exists', error);
  }
};

const response = (body = {}) => ({
  statusCode: body.error ? 500 : 200,
  headers: {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'OPTIONS,POST,GET',
  },
  body: JSON.stringify(body),
});

exports.handler = async (event) => {
  console.log('Received event:', JSON.stringify(event, null, 2));

  if (event.httpMethod === 'OPTIONS') {
    console.log('Handling OPTIONS request for CORS');
    return response();
  }

  if (!(await getCounterExists())) {
    try {
      await dynamoDb.send(
        new PutCommand({TableName: tableName, Item: {id: 'clicks', count: 0}})
      );
      console.log('Initialized click counter in DynamoDB');
    } catch (error) {
      console.error('Error initializing counter', error);
      return response({error: 'Could not initialize counter'});
    }
  }

  try {
    const result = await dynamoDb.send(
      new UpdateCommand({
        TableName: tableName,
        Key: {id: 'clicks'},
        UpdateExpression: 'SET #c = #c + :incr',
        ExpressionAttributeNames: {'#c': 'count'},
        ExpressionAttributeValues: {':incr': 1},
        ReturnValues: 'UPDATED_NEW',
      })
    );
    console.log('Counter updated successfully:', result);
    return response({count: result.Attributes.count});
  } catch (error) {
    console.error('Error updating the counter', error);
    return response({error: 'Could not update the counter'});
  }
};