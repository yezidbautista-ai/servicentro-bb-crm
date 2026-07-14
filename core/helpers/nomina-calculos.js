// core/helpers/nomina-calculos.js
//
// Constantes y fórmulas de nómina 2026 (Colombia) para Servicentro B&B.
// ⚠️ VERIFICAR CON CONTADOR ANTES DE USAR EN PRODUCCIÓN. Estos valores cambian cada año
// con el SMMLV y dependen de la situación tributaria específica del negocio.
//
// Fuentes:
// - SMMLV y auxilio de transporte 2026: Decretos 1469 y 1470 de 2025 (Min. Trabajo).
//   Estado legal: el Decreto 1469/2025 fue suspendido provisionalmente por el Consejo de
//   Estado el 12-feb-2026; el Decreto 0159/2026 mantuvo $1.750.905 de forma transitoria
//   mientras el Consejo de Estado decide de fondo. Revisar si hay novedad antes de cerrar
//   nómina de fin de año.
// - Exoneración de aportes: Art. 114-1 del Estatuto Tributario (Ley 1819 de 2016).

export const SMMLV_2026 = 1750905;
export const AUXILIO_TRANSPORTE_2026 = 249095;
export const TOPE_AUXILIO_TRANSPORTE = SMMLV_2026 * 2; // hasta 2 SMMLV se tiene derecho
export const UMBRAL_EXONERACION_ART_114_1 = SMMLV_2026 * 10; // 17.509.050

// --- Situación específica de Servicentro B&B (confirmada por el usuario) ---
// Persona natural con NIT, 2 funcionarios en nómina (>= 2 trabajadores).
// El Art. 114-1 E.T. exonera a personas naturales empleadoras del pago de salud,
// ICBF y SENA por trabajadores que devenguen menos de 10 SMMLV, EXCEPTO cuando el
// empleador tiene menos de 2 trabajadores. Con 2 funcionarios, la excepción no aplica,
// así que en principio SÍ opera la exoneración (salud + ICBF + SENA, no solo ICBF/SENA).
// ⚠️ Confirma esto con tu contador antes de producción — depende también de que
// Servicentro B&B esté al día como declarante de renta y se evalúa por trabajador.
export const APLICA_EXONERACION_ART_114_1 = true; // TODO: confirmar con contador

export const PORCENTAJES = {
  // --- A cargo del empleador ---
  salud_empleador: 0.085, // exonerado si APLICA_EXONERACION_ART_114_1 y salario < umbral
  pension_empleador: 0.12, // nunca se exonera
  arl: 0.02436, // Confirmado por el usuario: Riesgo 3 (Clase III) = 2.436% del IBC,
  // fijado por Decreto 1607/2002 y 1772/1994, a cargo 100% del empleador.
  caja_compensacion: 0.04, // nunca se exonera
  icbf: 0.03, // exonerado si APLICA_EXONERACION_ART_114_1 y salario < umbral
  sena: 0.02, // exonerado si APLICA_EXONERACION_ART_114_1 y salario < umbral

  // --- Prestaciones sociales (provisión mensual) ---
  prima: 0.0833,
  cesantias: 0.0833,
  intereses_cesantias: 0.12, // anual sobre cesantías acumuladas, prorrateado mensualmente
  vacaciones: 0.0417,

  // --- A cargo del trabajador (se descuentan del neto, no son costo del empleador) ---
  salud_empleado: 0.04,
  pension_empleado: 0.04,
};

/**
 * Auxilio de transporte: solo para quienes ganan hasta 2 SMMLV.
 */
export function calcularAuxilioTransporte(salarioBasico) {
  return salarioBasico < TOPE_AUXILIO_TRANSPORTE ? AUXILIO_TRANSPORTE_2026 : 0;
}

/**
 * Liquidación para contratistas por prestación de servicios: NO son
 * empleados, así que no llevan parafiscales, prestaciones sociales, ni
 * aportes patronales — el "costo total empleador" es simplemente el valor
 * mensual acordado. Se sigue devolviendo la misma forma de objeto que
 * calcularLiquidacionMensual (con ceros donde no aplica) para no tener que
 * ramificar el esquema de `nomina_liquidaciones`.
 */
export function calcularLiquidacionPrestacionServicios(valorMensual) {
  return {
    salario_base: valorMensual,
    auxilio_transporte: 0,
    salud_empleado: 0,
    pension_empleado: 0,
    salud_empleador: 0,
    pension_empleador: 0,
    arl: 0,
    caja_compensacion: 0,
    icbf: 0,
    sena: 0,
    prima: 0,
    cesantias: 0,
    intereses_cesantias: 0,
    vacaciones: 0,
    costo_total_empleador: valorMensual,
    neto_pagado: valorMensual,
    exonerado: false,
  };
}

/**
 * Liquida una nómina mensual completa para un funcionario.
 * Lanza un error si el % de ARL no ha sido configurado — evitamos silenciosamente
 * calcular con un supuesto no confirmado.
 */
export function calcularLiquidacionMensual(salarioBasico) {
  if (PORCENTAJES.arl === null) {
    throw new Error(
      'PORCENTAJES.arl no está definido. Confirma la clase de riesgo ARL (I a V) ' +
        'con el contador/ARL antes de liquidar nómina.'
    );
  }

  const auxilioTransporte = calcularAuxilioTransporte(salarioBasico);
  const exonerado =
    APLICA_EXONERACION_ART_114_1 && salarioBasico < UMBRAL_EXONERACION_ART_114_1;

  // Base de salud/pensión/ARL/parafiscales: NO incluye auxilio de transporte.
  const baseSeguridadSocial = salarioBasico;
  // Base de prima/cesantías: SÍ incluye auxilio de transporte.
  const basePrestacional = salarioBasico + auxilioTransporte;

  const saludEmpleado = baseSeguridadSocial * PORCENTAJES.salud_empleado;
  const pensionEmpleado = baseSeguridadSocial * PORCENTAJES.pension_empleado;

  const saludEmpleador = exonerado ? 0 : baseSeguridadSocial * PORCENTAJES.salud_empleador;
  const pensionEmpleador = baseSeguridadSocial * PORCENTAJES.pension_empleador;
  const arl = baseSeguridadSocial * PORCENTAJES.arl;
  const cajaCompensacion = baseSeguridadSocial * PORCENTAJES.caja_compensacion;
  const icbf = exonerado ? 0 : baseSeguridadSocial * PORCENTAJES.icbf;
  const sena = exonerado ? 0 : baseSeguridadSocial * PORCENTAJES.sena;

  const prima = basePrestacional * PORCENTAJES.prima;
  const cesantias = basePrestacional * PORCENTAJES.cesantias;
  const interesesCesantias = cesantias * PORCENTAJES.intereses_cesantias;
  const vacaciones = salarioBasico * PORCENTAJES.vacaciones; // no incluye auxilio de transporte

  const costoTotalEmpleador =
    salarioBasico +
    auxilioTransporte +
    saludEmpleador +
    pensionEmpleador +
    arl +
    cajaCompensacion +
    icbf +
    sena +
    prima +
    cesantias +
    interesesCesantias +
    vacaciones;

  const netoPagado = salarioBasico + auxilioTransporte - saludEmpleado - pensionEmpleado;

  return {
    salario_base: salarioBasico,
    auxilio_transporte: auxilioTransporte,
    salud_empleado: saludEmpleado,
    pension_empleado: pensionEmpleado,
    salud_empleador: saludEmpleador,
    pension_empleador: pensionEmpleador,
    arl,
    caja_compensacion: cajaCompensacion,
    icbf,
    sena,
    prima,
    cesantias,
    intereses_cesantias: interesesCesantias,
    vacaciones,
    costo_total_empleador: costoTotalEmpleador,
    neto_pagado: netoPagado,
    exonerado,
  };
}
