// backend1/routes/reportes.js
const express = require('express');
const router = express.Router();
const Sale = require('../models/Venta');
const PDFDocument = require('pdfkit');
const ExcelJS = require('exceljs');
const fs = require('fs'); // Para leer el logo
const path = require('path');

// -------------------------------------------------------------------
// HU18: Generar reporte de ventas en PDF
// GET /reportes/ventas/pdf
// -------------------------------------------------------------------
router.get('/ventas/pdf', async (req, res) => {
  try {
    const ventas = await Sale.find().sort({ sale_date: -1 });

    // Configurar los headers para que el navegador entienda que es un PDF
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename=reporte_ventas.pdf');

    // Inicializar PDFKit
    const doc = new PDFDocument({ margin: 50 });
    
    // Conectar el documento a la respuesta HTTP
    doc.pipe(res);

    // Título del documento
    doc.fontSize(20).text('Reporte Oficial de Ventas', { align: 'center' });
    doc.moveDown();

    // Iterar sobre las ventas para imprimirlas
    ventas.forEach(venta => {
      doc.fontSize(12).text(`ID Venta: ${venta._id}`);
      doc.fontSize(10).text(`Fecha: ${venta.sale_date.toLocaleDateString()}`);
      doc.text(`Total: $${venta.total_amount}`);
      doc.text('Productos:');
      
      venta.items.forEach(item => {
        doc.text(` - ${item.quantity}x ${item.name} ($${item.price_at_sale})`, { indent: 20 });
      });
      doc.moveDown();
    });

    // Finalizar el documento
    doc.end();

  } catch (error) {
    res.status(500).json({ error: 'Error al generar el PDF', detalle: error.message });
  }
});

// -------------------------------------------------------------------
// HU19: Exportar reporte de ventas en Excel con Logo
// GET /reportes/ventas/excel
// -------------------------------------------------------------------
router.get('/ventas/excel', async (req, res) => {
  try {
    const ventas = await Sale.find().sort({ sale_date: -1 });
    const workbook = new ExcelJS.Workbook();
    const worksheet = workbook.addWorksheet('Reporte de Ventas');

    // 1. Agregar el Logo de la empresa
    // IMPORTANTE: Asegúrate de tener una imagen llamada 'logo.png' en la raíz de tu backend1
    const logoPath = path.join(__dirname, '../logo.png'); 
    if (fs.existsSync(logoPath)) {
      const logoId = workbook.addImage({
        filename: logoPath,
        extension: 'png',
      });
      // Colocar el logo en la celda A1 (rango A1:B3)
      worksheet.addImage(logoId, 'A1:B3');
    }

    // Dejar espacio para el logo
    worksheet.addRow([]);
    worksheet.addRow([]);
    worksheet.addRow([]);
    worksheet.addRow(['', '', 'REPORTE OFICIAL DE VENTAS']).font = { size: 16, bold: true };
    worksheet.addRow([]);

    // 2. Definir las columnas
    worksheet.columns = [
      { header: 'ID Venta', key: 'id', width: 30 },
      { header: 'Fecha', key: 'fecha', width: 20 },
      { header: 'Total ($)', key: 'total', width: 15 },
      { header: 'Estado', key: 'estado', width: 15 },
      { header: 'Método de Pago', key: 'pago', width: 20 }
    ];

    // Dar estilo a la fila de encabezados
    worksheet.getRow(6).font = { bold: true };

    // 3. Insertar los datos
    ventas.forEach(venta => {
      worksheet.addRow({
        id: venta._id.toString(),
        fecha: venta.sale_date.toLocaleDateString(),
        total: venta.total_amount,
        estado: venta.status,
        pago: venta.payment_method
      });
    });

    // 4. Configurar headers HTTP y enviar
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename=reporte_ventas.xlsx');

    await workbook.xlsx.write(res);
    res.end();

  } catch (error) {
    res.status(500).json({ error: 'Error al generar el Excel', detalle: error.message });
  }
});

module.exports = router;