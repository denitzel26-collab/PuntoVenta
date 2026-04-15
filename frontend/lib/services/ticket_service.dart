import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/venta_model.dart';

class TicketService {
  static Future<void> generarTicket({
    required List<VentaItem> items,
    required double total,
    required String metodo,
    required double pagoCon,
    required double cambio,
  }) async {
    final pdf = pw.Document();
    final date = DateTime.now();
    pw.MemoryImage? logo;

    try {
      final imageByte = await rootBundle.load('assets/logo.png');
      logo = pw.MemoryImage(imageByte.buffer.asUint8List());
    } catch (e) {
      print("Logo no cargado");
    }

    // --- AJUSTES DE PÁGINA PARA USAR HOJA COMPLETA ---
    final formatoTicket = PdfPageFormat.a4;

    pdf.addPage(
      pw.Page(
        pageFormat: formatoTicket,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(18),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    if (logo != null) pw.Image(logo, width: 60, height: 60),
                    if (logo != null) pw.SizedBox(width: 10),
                    pw.Text("Ticket de compra", 
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 20)),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text("Fecha: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}", style: const pw.TextStyle(fontSize: 15)),
                      pw.Text("Método: $metodo", style: const pw.TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey300),

                ...items.map((i) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 3),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        child: pw.Text("${i.quantity}x ${i.name}", style: const pw.TextStyle(fontSize: 15)),
                      ),
                      pw.Text("\$${(i.quantity * i.priceAtSale).toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 15)),
                    ],
                  ),
                )),

                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text("TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                    pw.Text("\$${total.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                  ],
                ),

                if (metodo == "Efectivo") ...[
                  pw.SizedBox(height: 6),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Pagó con:", style: const pw.TextStyle(fontSize: 15)),
                      pw.Text("\$${pagoCon.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 15)),
                    ],
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text("Cambio:", style: const pw.TextStyle(fontSize: 16)),
                      pw.Text("\$${cambio.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 16)),
                    ],
                  ),
                ],
                
                pw.SizedBox(height: 18),
                pw.Center(child: pw.Text("¡Gracias por su compra!", style: pw.TextStyle(fontSize: 12, fontItalic: pw.Font.helveticaOblique()))),
                pw.SizedBox(height: 5),
              ],
            ),
          );
        },
      ),
    );

    // --- ESTO ACTIVA LA PREVISUALIZACIÓN AJUSTADA ---
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      // 'format' aquí debe ser el nuestro para que la ventana de impresión no use A4 por defecto
      format: formatoTicket, 
      name: 'Ticket_${date.millisecondsSinceEpoch}',
      dynamicLayout: false, // Importante para mantener el tamaño que calculamos
    );
  }
}