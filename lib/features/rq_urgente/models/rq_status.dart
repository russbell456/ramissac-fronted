import 'package:flutter/material.dart';

const estadosRqItem = {
  'PENDIENTE': 'Pendiente',
  'POR_COMPRAR': 'Por comprar',
  'EN_PROCESO': 'En proceso',
  'COMPRADO': 'Comprado',
  'ATENDIDO_STOCK': 'Atendido con stock',
  'CERRADO_SIN_COMPRA': 'Cerrado sin compra',
};

String etiquetaRq(String estado) =>
    const {
      'BORRADOR': 'Borrador',
      'FIRMADO': 'Firmado · envío pendiente',
      'ENVIADO': 'Enviado',
      'EN_PROCESO': 'En atención',
      'FINALIZADO': 'Finalizado',
    }[estado] ??
    estadosRqItem[estado] ??
    estado;

Color colorEstadoRq(String estado) => switch (estado) {
      'COMPRADO' || 'ATENDIDO_STOCK' || 'FINALIZADO' => const Color(0xFF28734D),
      'EN_PROCESO' || 'POR_COMPRAR' => const Color(0xFF966000),
      'CERRADO_SIN_COMPRA' => const Color(0xFF666666),
      _ => const Color(0xFF21428C),
    };

bool esLogistica(String rol) => [
      'admin',
      'logistica',
      'logística',
      'almacenero'
    ].contains(rol.toLowerCase());
bool esCompras(String rol) =>
    ['admin', 'compras', 'comprador'].contains(rol.toLowerCase());

bool coincideEstadoRq(String estado, String filtro) => switch (filtro) {
      'Pendientes' => ['BORRADOR', 'FIRMADO'].contains(estado),
      'Enviados' => ['ENVIADO', 'EN_PROCESO'].contains(estado),
      'Finalizados' => estado == 'FINALIZADO',
      _ => true,
    };
