const mysql = require('mysql2/promise');
require('dotenv').config();

class Database {
  constructor() {
    this.pool = mysql.createPool({
      host: process.env.DB_HOST || 'mysql-cogitare.alwaysdata.net',
      port: process.env.DB_PORT || 3306,
      user: process.env.DB_USER || 'cogitare',
      password: process.env.DB_PASSWORD || '2Ytt1tl1b1o1vCuXpV2T',
      database: process.env.DB_NAME || 'cogitare_bd',
      waitForConnections: true,
      connectionLimit: 10,
      queueLimit: 0,
      acquireTimeout: 60000,
      timeout: 60000,
      reconnect: true
    });
  }

  async query(sql, params = []) {
    try {
      const [rows] = await this.pool.execute(sql, params);
      return rows;
    } catch (error) {
      console.error('Erro na query:', error);
      throw error;
    }
  }

  async getConnection() {
    return await this.pool.getConnection();
  }

  async close() {
    await this.pool.end();
  }
}

module.exports = new Database();
