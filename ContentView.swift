import SwiftUI
//Modelo de datos para almacenar id unico, nombre, precio, stock y emoji
struct Producto: Identifiable {
    let id = UUID()
    let nombre: String
    let precio: Double
    var stock: Int
    let emoji: String
}

//Vista principal
struct ContentView: View {
    //Lista de productos que se mostraran
    @State private var productos = [
        Producto(nombre: "iPhone Pro", precio: 999.0, stock: 5, emoji: "📱"),
        Producto(nombre: "MacBook Air", precio: 1200.0, stock: 3, emoji: "💻"),
        Producto(nombre: "AirPods Max", precio: 549.0, stock: 8, emoji: "🎧"),
        Producto(nombre: "Apple Watch", precio: 399.0, stock: 2, emoji: "⌚")
    ]
    
    @State private var productoSeleccionado: Producto? // Producto que se va a comprar
    @State private var cantidadSeleccionada: Int = 1  // Cantidad en el Stepper

    var body: some View {
        ZStack {
            //Contenedor vertical
            VStack(spacing: 20) {
                Text("Productos Premium")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .padding(.top, 10)
                
                VStack(spacing: 15) {
                    ForEach($productos) { $item in
                        // Pasamos una acción al componente para abrir la ventana
                        FilaProducto(producto: $item) {
                            //Al dar clic en la fila se configuran los datos para la ventana modal
                            self.cantidadSeleccionada = 1
                            self.productoSeleccionado = item
                        }
                    }
                }
                .frame(maxWidth: 500)
                .padding(.horizontal)
                
                Spacer()
            }
        }
        .sheet(item: $productoSeleccionado) { prod in
            //Vista desde abajo
            VentanaConfirmacion(
                producto: prod,
                cantidad: $cantidadSeleccionada,
                onCancel: { productoSeleccionado = nil },
                onConfirm: { cant in
                    procesarCompra(id: prod.id, cantidad: cant)//Cerrar sin confirmar
                }
            )
            .presentationDetents([.medium]) // Hace que la ventana sea de tamaño medio
        }
    }
    
    // Busca el producto y resta la cantidad del stock
    func procesarCompra(id: UUID, cantidad: Int) {
        if let index = productos.firstIndex(where: { $0.id == id }) {
            productos[index].stock -= cantidad
        }
        productoSeleccionado = nil // Cierra la ventana despues de la compra
    }
}

// Fila de los productos
struct FilaProducto: View {
    @Binding var producto: Producto
    var clickComprar: () -> Void // Acción que recibimos del padre
    
    var body: some View {
        HStack(spacing: 20) {
            Text(producto.emoji)
                .font(.system(size: 50))
                .frame(width: 90, height: 90)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(20)
            //Informacion textual
            VStack(alignment: .leading, spacing: 6) {
                Text(producto.nombre)
                    .font(.title3.bold())
                
                Text("$\(producto.precio, specifier: "%.0f")")
                    .font(.headline)
                    .foregroundColor(.green)
                //Indicador del stock. Rojo si ya no hay
                Text("Disponibles: \(producto.stock)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(producto.stock > 0 ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    .foregroundColor(producto.stock > 0 ? .green : .red)
                    .cornerRadius(5)
            }

            Spacer()
            //Boton que abre la ventana modal
            Button(action: clickComprar) {
                VStack {
                    Image(systemName: "cart.badge.plus")
                        .font(.title2)
                    Text(producto.stock > 0 ? "Comprar" : "Agotado")
                        .font(.caption2.bold())
                }
                .frame(width: 80, height: 80)
                .background(producto.stock > 0 ? Color.blue : Color.gray.opacity(0.3))
                .foregroundColor(.white)
                .cornerRadius(20)
            }
            .disabled(producto.stock == 0) //Bloquea boton si ya no hay stock
        }
        .padding()
        .frame(minHeight: 120)
        .background(Color.white)
        .cornerRadius(25)
        .shadow(color: .black.opacity(0.08), radius: 15, x: 0, y: 8)
    }
}

// Venta de confirmacion
struct VentanaConfirmacion: View {
    let producto: Producto
    @Binding var cantidad: Int
    var onCancel: () -> Void
    var onConfirm: (Int) -> Void
    
    // Calculamos el total dinámicamente
    var totalAPagar: Double {
        Double(cantidad) * producto.precio
    }
    
    var body: some View {
        VStack(spacing: 25) {
            Text("Detalle de Compra")
                .font(.title.bold())
            
            VStack(spacing: 10) {
                Text(producto.emoji).font(.system(size: 60))
                Text(producto.nombre).font(.headline)
                Text("Precio unitario: $\(producto.precio, specifier: "%.2f")")
                    .foregroundColor(.secondary)
            }
            
            // Selector de cantidad limitado a lo existente
            Stepper("Selecciona cantidad: \(cantidad)", value: $cantidad, in: 1...producto.stock)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            
            // Mostrar Total
            HStack {
                Text("Total a pagar:")
                    .font(.headline)
                Spacer()
                Text("$\(totalAPagar, specifier: "%.2f")")
                    .font(.title2.bold())
                    .foregroundColor(.green)
            }
            .padding(.horizontal)
            
            // Botones Cancelar y Comprar
            HStack(spacing: 20) {
                Button("Cancelar") {
                    onCancel()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.1))
                .foregroundColor(.red)
                .cornerRadius(15)
                
                Button("Confirmar") {
                    onConfirm(cantidad)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(15)
            }
        }
        .padding(30)
    }
}

#Preview {
    ContentView()
}
