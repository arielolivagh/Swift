import SwiftUI

// Estructura para almacenar id unico, tipo de transacción, monto y fecha.
struct Transaccion: Identifiable {
    let id = UUID()
    let tipo: TipoTransaccion
    let monto: Double
    let fecha: Date
}

// Enumeración para  los movimientos de la cuenta.
enum TipoTransaccion {
    case deposito, retiro, consulta
}

//Vista Principal
struct ContentView: View {
    let azulPrimario = Color(red: 0.07, green: 0.15, blue: 0.28)
    let grisPizarra = Color(red: 0.44, green: 0.50, blue: 0.59)
    let verdeBosque = Color(red: 0.13, green: 0.35, blue: 0.27)
    let rojoInstitucional = Color(red: 0.45, green: 0.12, blue: 0.12)
    let doradoConsultas = Color(red: 0.72, green: 0.53, blue: 0.04)
    
    @State private var saldo: Double = 0.00
    @State private var montoEntrada: String = ""
    @State private var historial: [Transaccion] = []
    @State private var sesionActiva: Bool = true
    @State private var mensajeEstado: String = "Conexión segura establecida"
    @State private var colorMensaje: Color = .secondary

    var body: some View {
        NavigationStack {
            ZStack {
                #if os(iOS)
                Color(UIColor.systemGroupedBackground).ignoresSafeArea()
                #else
                Color.gray.opacity(0.1).ignoresSafeArea()
                #endif
                
                if sesionActiva {
                    VStack(spacing: 0) {
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                
                                //Saldo Principal
                                TarjetaSaldo(saldo: saldo, colorFondo: azulPrimario)
                                
                                //Panel de Operaciones
                                VStack(alignment: .leading, spacing: 18) {
                                    Text("OPERACIONES DISPONIBLES")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(grisPizarra)
                                        .tracking(1.2)
                                    
                                    // Campo de entrada para  depósito y retiro
                                    HStack {
                                        Text("$").font(.title2).foregroundColor(azulPrimario)
                                        TextField("Introduzca monto", text: $montoEntrada)
                                            #if os(iOS)
                                            .keyboardType(.decimalPad)
                                            #endif
                                            .font(.title3)
                                    }
                                    .padding()
                                    .background(Color.white)
                                    .cornerRadius(8)
                                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                                    
                                    // Botones de acción
                                    VStack(spacing: 12) {
                                        HStack(spacing: 12) {
                                            BotonAccionFormal(titulo: "DEPOSITAR", color: verdeBosque, icono: "arrow.down.circle.fill") {
                                                ejecutarDeposito()
                                            }
                                            
                                            BotonAccionFormal(titulo: "RETIRAR", color: azulPrimario, icono: "arrow.up.circle.fill") {
                                                ejecutarRetiro()
                                            }
                                        }
                                        
                                        // Botón para consultar Saldo
                                        BotonAccionFormal(titulo: "CONSULTAR ESTADO DE CUENTA", color: doradoConsultas, icono: "doc.text.magnifyingglass") {
                                            ejecutarConsulta()
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                
                                // Notificación del sistema
                                Text(mensajeEstado)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(colorMensaje)
                                    .padding(.vertical, 8)
                                    .frame(maxWidth: .infinity)
                                    .background(colorMensaje.opacity(0.05))
                                
                                // Historia de Actividad
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("ACTIVIDAD RECIENTE")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(grisPizarra)
                                        .padding(.horizontal)
                                        .tracking(1.2)
                                    
                                    VStack(spacing: 0) {
                                        if historial.isEmpty {
                                            VStack(spacing: 8) {
                                                Image(systemName: "clock.badge.exclamationmark").font(.largeTitle)
                                                Text("Sin movimientos registrados")
                                            }
                                            .foregroundColor(.gray.opacity(0.6))
                                            .padding(.vertical, 40)
                                            .frame(maxWidth: .infinity)
                                        } else {
                                            ForEach(historial.reversed()) { item in
                                                FilaTransaccion(transaccion: item, colorAzul: azulPrimario)
                                                if item.id != historial.first?.id {
                                                    Divider().padding(.leading, 60)
                                                }
                                            }
                                        }
                                    }
                                    .background(Color.white)
                                    .cornerRadius(12)
                                    .padding(.horizontal)
                                    .shadow(color: .black.opacity(0.03), radius: 10, x: 0, y: 5)
                                }
                            }
                            .padding(.vertical)
                            .frame(maxWidth: 600)
                        }
                        
                        // Cerrar sesión
                        Button(action: { sesionActiva = false }) {
                            Text("CERRAR SESIÓN")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(rojoInstitucional)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .overlay(Rectangle().frame(height: 1).foregroundColor(Color.gray.opacity(0.2)), alignment: .top)
                        }
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    VistaSalida(colorPrimario: azulPrimario) {
                        reiniciarSistema()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Global Bank")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 400, minHeight: 650)
        #endif
    }

    // Procesa una consulta formal de saldo.
    private func ejecutarConsulta() {
        // En una aplicación real, aquí se llamaría a una API de consulta sincronizada
        let fechaActual = Date().formatted(date: .abbreviated, time: .shortened)
        notificar("Consulta realizada: Saldo de $\(String(format: "%.2f", saldo)) al \(fechaActual)", color: doradoConsultas)
    }
    //Deposito
    private func ejecutarDeposito() {
        let entradaLimpia = montoEntrada.replacingOccurrences(of: ",", with: ".")
        guard let monto = Double(entradaLimpia), monto > 0 else {
            notificar("Error: Ingrese un monto de depósito válido", color: .orange)
            return
        }
        
        saldo += monto
        registrarTransaccion(tipo: .deposito, monto: monto)
        notificar("Operación exitosa: Depósito de $\(String(format: "%.2f", monto)) confirmado", color: verdeBosque)
        montoEntrada = ""
    }
    //Retiro
    private func ejecutarRetiro() {
        let entradaLimpia = montoEntrada.replacingOccurrences(of: ",", with: ".")
        guard let monto = Double(entradaLimpia), monto > 0 else {
            notificar("Error: Ingrese un monto de retiro válido", color: .orange)
            return
        }
        
        if monto <= saldo {
            saldo -= monto
            registrarTransaccion(tipo: .retiro, monto: monto)
            notificar("Operación exitosa: Retiro de $\(String(format: "%.2f", monto)) procesado", color: azulPrimario)
            montoEntrada = ""
        } else {
            notificar("Fondos insuficientes para retirar $\(String(format: "%.2f", monto))", color: rojoInstitucional)
        }
    }
    //Registra transacción
    private func registrarTransaccion(tipo: TipoTransaccion, monto: Double) {
        let nueva = Transaccion(tipo: tipo, monto: monto, fecha: Date())
        historial.append(nueva)
    }
    //Notificar
    private func notificar(_ texto: String, color: Color) {
        mensajeEstado = texto
        colorMensaje = color
    }
    //Reiniciar sistema
    private func reiniciarSistema() {
        saldo = 0.00
        historial = []
        sesionActiva = true
        mensajeEstado = "Sesión segura restaurada"
        colorMensaje = .secondary
    }
}
//Estructura de tarjeta
struct TarjetaSaldo: View {
    var saldo: Double
    var colorFondo: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("CUENTA DE AHORROS PREFERENTE").font(.caption).fontWeight(.bold).opacity(0.7)
                    Text("IBAN: ES45 **** **** 9012").font(.caption2).opacity(0.5)
                }
                Spacer()
                Image(systemName: "lock.shield.fill").font(.title3)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Balance Actual").font(.subheadline).opacity(0.8)
                Text("$\(saldo, specifier: "%.2f")")
                    .font(.system(size: 38, weight: .light, design: .serif))
            }
        }
        .padding(30)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(colorFondo)
        .foregroundColor(.white)
        .cornerRadius(6)
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 8)
    }
}
//Transacciones
struct FilaTransaccion: View {
    let transaccion: Transaccion
    let colorAzul: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: transaccion.tipo == .deposito ? "tray.and.arrow.down.fill" : "paperplane.fill")
                        .foregroundColor(colorAzul)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaccion.tipo == .deposito ? "Abono de Fondos" : "Retiro de Efectivo")
                    .font(.system(size: 15, weight: .semibold))
                Text(transaccion.fecha, style: .date).font(.caption2).foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("\(transaccion.tipo == .deposito ? "+" : "-") $\(transaccion.monto, specifier: "%.2f")")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(transaccion.tipo == .deposito ? .green : .primary)
        }
        .padding()
        .frame(maxWidth: .infinity)
    }
}

struct BotonAccionFormal: View {
    var titulo: String
    var color: Color
    var icono: String
    var action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icono)
                Text(titulo).font(.system(size: 12, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(4)
        }
    }
}
//Salida
struct VistaSalida: View {
    var colorPrimario: Color
    var alReiniciar: () -> Void
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            Image(systemName: "checkmark.seal.fill").font(.system(size: 70)).foregroundColor(colorPrimario)
            
            VStack(spacing: 12) {
                Text("SESIÓN FINALIZADA").font(.headline).tracking(2)
                Text("Gracias por operar con Global Bank.\nSu seguridad es nuestra prioridad.")
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            Spacer()
            Button(action: alReiniciar) {
                Text("REINTENTAR ACCESO").font(.caption).fontWeight(.bold).padding()
                    .frame(maxWidth: .infinity).background(colorPrimario).foregroundColor(.white).cornerRadius(4)
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    ContentView()
}
