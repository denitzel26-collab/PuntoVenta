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

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80, // Formato ticket de 80mm
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Text("MERCADOTIENDA", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              ),
              pw.Center(child: pw.Text("Ticket de Venta")),
              pw.Divider(),
              pw.Text("Fecha: ${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}"),
              pw.Text("Método: $metodo"),
              pw.Divider(),
              // Lista de productos
              ...items.map((i) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("${i.quantity}x ${i.name.substring(0, i.name.length > 15 ? 15 : i.name.length)}"),
                  pw.Text("\$${(i.quantity * i.priceAtSale).toStringAsFixed(2)}"),
                ],
              )),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("TOTAL:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.Text("\$${total.toStringAsFixed(2)}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              if (metodo == "Efectivo") ...[
                pw.Text("Pagó con: \$${pagoCon.toStringAsFixed(2)}"),
                pw.Text("Cambio: \$${cambio.toStringAsFixed(2)}"),
              ],
              pw.SizedBox(height: 20),
              pw.Center(child: pw.Text("¡Gracias por su compra!")),
            ],
          );
        },
      ),
    );

    // Abre la ventana de impresión/vista previa
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}