const express = require('express');
const bcrypt = require('bcryptjs');
const db = require('../config/database');
const { generateToken, authenticateToken } = require('../middleware/auth');

const router = express.Router();

// Endpoint de teste
router.get('/test', (req, res) => {
  res.json({
    success: true,
    message: 'Auth endpoint funcionando',
    timestamp: new Date().toISOString()
  });
});

// Endpoint de teste de login sem bcrypt
router.post('/test-login', async (req, res) => {
  try {
    const { email, tipo } = req.body;
    console.log('Test login request:', { email, tipo });
    
    // Usar os nomes corretos das colunas baseado no tipo
    let idColumn, nomeColumn, emailColumn;
    if (tipo === 'cuidador') {
      idColumn = 'IdCuidador';
      nomeColumn = 'Nome';
      emailColumn = 'Email';
    } else if (tipo === 'responsavel') {
      idColumn = 'IdResponsavel';
      nomeColumn = 'Nome';
      emailColumn = 'Email';
    } else {
      return res.status(400).json({
        success: false,
        message: 'Tipo inválido'
      });
    }
    
    const users = await db.query(
      `SELECT ${idColumn} as id, ${nomeColumn} as nome, ${emailColumn} as email FROM ${tipo} WHERE ${emailColumn} = ?`,
      [email]
    );
    
    console.log(`Found ${users.length} users`);
    
    res.json({
      success: true,
      message: 'Test login successful',
      users: users
    });
  } catch (error) {
    console.error('Test login error:', error);
    res.status(500).json({
      success: false,
      message: 'Test login failed',
      error: error.message
    });
  }
});

// Login - valida tipo específico para evitar conflitos
router.post('/login', async (req, res) => {
  try {
    console.log('Login request received:', { 
      email: req.body.email, 
      tipo: req.body.tipo,
      hasSenha: !!req.body.senha 
    });
    
    const { email, senha, tipo } = req.body;

    if (!email || !senha || !tipo) {
      console.log('Missing required fields:', { email: !!email, senha: !!senha, tipo: !!tipo });
      return res.status(400).json({
        success: false,
        message: 'Email, senha e tipo são obrigatórios'
      });
    }

    // Validar tipo de usuário permitido
    const allowedTypes = ['cuidador', 'responsavel'];
    if (!allowedTypes.includes(tipo)) {
      return res.status(400).json({
        success: false,
        message: 'Tipo de usuário inválido. Use: cuidador ou responsavel'
      });
    }

    // Determinar a tabela e colunas baseadas no tipo
    const tableName = tipo;
    let idColumn, nomeColumn, emailColumn, senhaColumn;
    
    if (tipo === 'cuidador') {
      idColumn = 'IdCuidador';
      nomeColumn = 'Nome';
      emailColumn = 'Email';
      senhaColumn = 'Senha';
    } else if (tipo === 'responsavel') {
      idColumn = 'IdResponsavel';
      nomeColumn = 'Nome';
      emailColumn = 'Email';
      senhaColumn = 'Senha';
    }
    
    console.log(`Searching in table: ${tableName} for email: ${email}`);

    // Buscar usuário especificamente na tabela do tipo informado
    const users = await db.query(
      `SELECT ${idColumn} as id, ${nomeColumn} as nome, ${emailColumn} as email, ${senhaColumn} as senha FROM ${tableName} WHERE ${emailColumn} = ?`,
      [email]
    );
    
    console.log(`Found ${users.length} users in ${tableName}`);

    if (users.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Credenciais inválidas para o tipo de usuário informado'
      });
    }

    const user = users[0];

    // Verificar senha
    try {
      const validPassword = await bcrypt.compare(senha, user.senha);
      console.log('Password comparison result:', validPassword);
      if (!validPassword) {
        return res.status(401).json({
          success: false,
          message: 'Credenciais inválidas para o tipo de usuário informado'
        });
      }
    } catch (bcryptError) {
      console.error('Bcrypt error:', bcryptError);
      return res.status(500).json({
        success: false,
        message: 'Erro na validação da senha'
      });
    }

    // Gerar token
    const token = generateToken({
      id: user.id,
      email: user.email,
      tipo: tipo
    });

    res.json({
      success: true,
      message: 'Login realizado com sucesso',
      data: {
        token,
        user: {
          id: user.id,
          nome: user.nome,
          email: user.email,
          tipo: tipo
        }
      }
    });

  } catch (error) {
    console.error('Erro no login:', error);
    console.error('Error stack:', error.stack);
    res.status(500).json({
      success: false,
      message: 'Erro interno do servidor',
      error: process.env.NODE_ENV === 'development' ? error.message : undefined
    });
  }
});

// Verificar token
router.get('/verify', authenticateToken, (req, res) => {
  res.json({
    success: true,
    message: 'Token válido',
    data: {
      user: req.user
    }
  });
});

module.exports = router;
