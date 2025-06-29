const express = require('express');
const router = express.Router();
const checklistController = require('../controllers/checklist.controller');

// @route   POST /api/v1/generate-checklist
// @desc    Generate a new packing checklist
// @access  Public
router.post('/generate-checklist', checklistController.generateChecklist);

module.exports = router; 