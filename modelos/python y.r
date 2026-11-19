from abc import ABC, abstractmethod
import logging
import re


# =========================================================
# CONFIGURACIÓN DE REGISTRO DE EVENTOS Y ERRORES
# =========================================================
logging.basicConfig(
    filename="sistema_software_fj.log",
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    encoding="utf-8"
)
logger = logging.getLogger("SoftwareFJ")


# =========================================================
# EXCEPCIONES PERSONALIZADAS
# =========================================================
class SoftwareFJError(Exception):
    """Excepción base del sistema Software FJ."""


class ClienteInvalidoError(SoftwareFJError):
    """Error en los datos personales de un cliente."""


class ServicioNoDisponibleError(SoftwareFJError):
    """Error en la configuración o disponibilidad de un servicio."""


class ReservaError(SoftwareFJError):
    """Error durante la creación, confirmación, procesamiento o cancelación."""


# =========================================================
# CLASE ABSTRACTA GENERAL
# =========================================================
class EntidadBase(ABC):
    """Representa una entidad general del sistema."""

    def __init__(self, identificador: str):
        if not isinstance(identificador, str) or not identificador.strip():
            raise ValueError("El identificador no puede estar vacío.")
        self._identificador = identificador.strip()

    @property
    def identificador(self) -> str:
        return self._identificador

    @abstractmethod
    def obtener_detalles(self) -> str:
        """Devuelve una descripción de la entidad."""
        raise NotImplementedError


# =========================================================
# CLASE CLIENTE: ENCAPSULACIÓN Y VALIDACIONES
# =========================================================
class Cliente(EntidadBase):
    def __init__(self, identificador: str, nombre: str, correo: str, telefono: str):
        super().__init__(identificador)
        self.nombre = nombre
        self.correo = correo
        self.telefono = telefono

    @property
    def nombre(self) -> str:
        return self._nombre

    @nombre.setter
    def nombre(self, valor: str):
        if not isinstance(valor, str) or len(valor.strip()) < 2:
            raise ClienteInvalidoError("El nombre debe tener al menos dos caracteres.")
        self._nombre = valor.strip()

    @property
    def correo(self) -> str:
        return self._correo

    @correo.setter
    def correo(self, valor: str):
        patron = r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"
        if not isinstance(valor, str) or not re.fullmatch(patron, valor.strip()):
            raise ClienteInvalidoError(f"Correo electrónico inválido: {valor!r}.")
        self._correo = valor.strip().lower()

    @property
    def telefono(self) -> str:
        return self._telefono

    @telefono.setter
    def telefono(self, valor: str):
        if not isinstance(valor, str) or not valor.isdigit() or not 7 <= len(valor) <= 15:
            raise ClienteInvalidoError(
                "El teléfono debe contener entre 7 y 15 dígitos, sin espacios ni signos."
            )
        self._telefono = valor

    def obtener_detalles(self) -> str:
        return (
            f"Cliente [ID: {self.identificador}] - Nombre: {self.nombre}, "
            f"Correo: {self.correo}, Teléfono: {self.telefono}"
        )


# =========================================================
# CLASE ABSTRACTA SERVICIO
# =========================================================
class Servicio(EntidadBase, ABC):
    def __init__(self, identificador: str, nombre_servicio: str, costo_base: float):
        super().__init__(identificador)

        if not isinstance(nombre_servicio, str) or not nombre_servicio.strip():
            raise ServicioNoDisponibleError("El nombre del servicio es obligatorio.")
        self.nombre_servicio = nombre_servicio.strip()
        self.costo_base = costo_base
        self.disponible = True

    @property
    def costo_base(self) -> float:
        return self._costo_base

    @costo_base.setter
    def costo_base(self, valor: float):
        if isinstance(valor, bool) or not isinstance(valor, (int, float)) or valor <= 0:
            raise ServicioNoDisponibleError("El costo base debe ser un número mayor que cero.")
        self._costo_base = float(valor)

    def validar_disponibilidad(self):
        if not self.disponible:
            raise ServicioNoDisponibleError(
                f"El servicio {self.nombre_servicio} no está disponible."
            )

    @abstractmethod
    def calcular_costo(self, *args, **kwargs) -> float:
        """Calcula el costo según el tipo de servicio."""
        raise NotImplementedError

    @abstractmethod
    def describir_servicio(self) -> str:
        raise NotImplementedError

    @abstractmethod
    def obtener_detalles(self) -> str:
        raise NotImplementedError


# =========================================================
# SERVICIOS ESPECIALIZADOS: HERENCIA Y POLIMORFISMO
# =========================================================
class ReservaSalas(Servicio):
    def __init__(self, identificador: str, costo_base: float, capacidad_personas: int):
        super().__init__(identificador, "Reserva de Salas", costo_base)
        self.capacidad_personas = capacidad_personas

    @property
    def capacidad_personas(self) -> int:
        return self._capacidad_personas

    @capacidad_personas.setter
    def capacidad_personas(self, valor: int):
        if isinstance(valor, bool) or not isinstance(valor, int) or valor <= 0:
            raise ServicioNoDisponibleError("La capacidad debe ser un entero mayor que cero.")
        self._capacidad_personas = valor

    def calcular_costo(self, horas: int = 1, aplicar_impuesto: bool = True) -> float:
        self.validar_disponibilidad()
        if isinstance(horas, bool) or not isinstance(horas, int) or horas <= 0:
            raise ServicioNoDisponibleError("Las horas de reserva deben ser un entero mayor que cero.")
        if not isinstance(aplicar_impuesto, bool):
            raise ServicioNoDisponibleError("aplicar_impuesto debe ser True o False.")
        subtotal = self.costo_base * horas
        if aplicar_impuesto:
            subtotal *= 1.19
        return round(subtotal, 2)

    def describir_servicio(self) -> str:
        return (
            f"Servicio de Sala (ID: {self.identificador}) - "
            f"Capacidad: {self.capacidad_personas} personas."
        )

    def obtener_detalles(self) -> str:
        return self.describir_servicio()


class AlquilerEquipos(Servicio):
    def __init__(self, identificador: str, costo_base: float, tipo_equipo: str):
        super().__init__(identificador, "Alquiler de Equipos", costo_base)
        if not isinstance(tipo_equipo, str) or not tipo_equipo.strip():
            raise ServicioNoDisponibleError("Debe especificar el tipo de equipo.")
        self.tipo_equipo = tipo_equipo.strip()

    def calcular_costo(self, dias: int = 1, descuento_porcentaje: float = 0.0) -> float:
        self.validar_disponibilidad()
        if isinstance(dias, bool) or not isinstance(dias, int) or dias <= 0:
            raise ServicioNoDisponibleError("Los días de alquiler deben ser un entero mayor que cero.")
        if (isinstance(descuento_porcentaje, bool)
                or not isinstance(descuento_porcentaje, (int, float))
                or not 0 <= descuento_porcentaje <= 100):
            raise ServicioNoDisponibleError("El descuento debe estar entre 0 y 100.")
        subtotal = self.costo_base * dias
        return round(subtotal * (1 - descuento_porcentaje / 100), 2)

    def describir_servicio(self) -> str:
        return f"Alquiler de Equipo (ID: {self.identificador}) - Tipo: {self.tipo_equipo}."

    def obtener_detalles(self) -> str:
        return self.describir_servicio()


class AsesoriaEspecializada(Servicio):
    def __init__(self, identificador: str, costo_base: float, area_experteza: str):
        super().__init__(identificador, "Asesoría Especializada", costo_base)
        if not isinstance(area_experteza, str) or not area_experteza.strip():
            raise ServicioNoDisponibleError("Debe especificar el área de experticia.")
        self.area_experteza = area_experteza.strip()

    def calcular_costo(self, sesiones: int = 1, tarifa_plana_software: float = 0.0) -> float:
        self.validar_disponibilidad()
        if isinstance(sesiones, bool) or not isinstance(sesiones, int) or sesiones <= 0:
            raise ServicioNoDisponibleError("Las sesiones deben ser un entero mayor que cero.")
        if (isinstance(tarifa_plana_software, bool)
                or not isinstance(tarifa_plana_software, (int, float))
                or tarifa_plana_software < 0):
            raise ServicioNoDisponibleError("La tarifa plana no puede ser negativa.")
        total = (self.costo_base * sesiones) + tarifa_plana_software
        return round(total, 2)

    def describir_servicio(self) -> str:
        return (
            f"Asesoría Especializada (ID: {self.identificador}) - "
            f"Área: {self.area_experteza}."
        )

    def obtener_detalles(self) -> str:
        return self.describir_servicio()


# =========================================================
# RESERVA: CONTROL DE ESTADOS Y MANEJO DE EXCEPCIONES
# =========================================================
class Reserva:
    ESTADOS_VALIDOS = ("Creada", "Confirmada", "Cancelada", "Procesada")

    def __init__(
        self,
        id_reserva: str,
        cliente: Cliente,
        servicio: Servicio,
        duracion_parametro: int
    ):
        if not isinstance(id_reserva, str) or not id_reserva.strip():
            raise ReservaError("El identificador de la reserva es obligatorio.")
        if not isinstance(cliente, Cliente):
            raise ReservaError("La reserva requiere un objeto Cliente válido.")
        if not isinstance(servicio, Servicio):
            raise ReservaError("La reserva requiere un objeto Servicio válido.")
        if (isinstance(duracion_parametro, bool)
                or not isinstance(duracion_parametro, int)
                or duracion_parametro <= 0):
            raise ReservaError("La duración debe ser un entero mayor que cero.")

        servicio.validar_disponibilidad()
        self.id_reserva = id_reserva.strip()
        self.cliente = cliente
        self.servicio = servicio
        self.duracion_parametro = duracion_parametro
        self.estado = "Creada"
        self.costo_final = 0.0

    def confirmar_reserva(self):
        if self.estado != "Creada":
            raise ReservaError("Solo se puede confirmar una reserva en estado 'Creada'.")
        self.estado = "Confirmada"
        logger.info("Reserva %s confirmada.", self.id_reserva)

    def procesar_reserva(self, *args, **kwargs):
        """Procesa una reserva; admite las variantes de cálculo de cada servicio."""
        logger.info("Iniciando procesamiento de reserva %s.", self.id_reserva)

        if self.estado != "Confirmada":
            error = ReservaError("La reserva debe estar confirmada antes de procesarse.")
            logger.warning("No se procesó %s: %s", self.id_reserva, error)
            raise error

        # Asegura que la duración guardada en la reserva sea la usada en el cálculo.
        clave_duracion = {
            ReservaSalas: "horas",
            AlquilerEquipos: "dias",
            AsesoriaEspecializada: "sesiones",
        }[type(self.servicio)]

        if clave_duracion in kwargs and kwargs[clave_duracion] != self.duracion_parametro:
            error = ReservaError(
                f"La duración indicada ({kwargs[clave_duracion]}) no coincide "
                f"con la duración registrada ({self.duracion_parametro})."
            )
            logger.warning("Duración inconsistente en reserva %s.", self.id_reserva)
            raise error

        if not args and clave_duracion not in kwargs:
            kwargs[clave_duracion] = self.duracion_parametro

        try:
            self.costo_final = self.servicio.calcular_costo(*args, **kwargs)
        except (ServicioNoDisponibleError, TypeError, ValueError) as exc:
            logger.exception("Error al calcular el costo de la reserva %s.", self.id_reserva)
            raise ReservaError(
                f"No fue posible calcular el costo de la reserva {self.id_reserva}."
            ) from exc
        else:
            self.estado = "Procesada"
            logger.info(
                "Reserva %s procesada correctamente. Total: %.2f",
                self.id_reserva,
                self.costo_final
            )
            return self.costo_final
        finally:
            print(
                f"[LOG INTERNO] Finalizó el intento de procesamiento "
                f"de la reserva {self.id_reserva}."
            )

    def cancelar_reserva(self):
        if self.estado in ("Cancelada", "Procesada"):
            error = ReservaError(
                f"No se puede cancelar una reserva que está en estado '{self.estado}'."
            )
            logger.warning("Intento de cancelación no permitido: %s", error)
            raise error

        self.estado = "Cancelada"
        logger.info("Reserva %s cancelada correctamente.", self.id_reserva)
        return f"La reserva {self.id_reserva} fue cancelada."


# =========================================================
# SIMULACIÓN DE OPERACIONES VÁLIDAS E INVÁLIDAS
# =========================================================
def ejecutar_operacion(numero: int, descripcion: str, funcion):
    print(f"\n--- Operación {numero}: {descripcion} ---")
    try:
        resultado = funcion()
    except SoftwareFJError as exc:
        logger.warning("Operación %s controlada: %s", numero, exc)
        print(f"Excepción controlada: {exc}")
    except Exception as exc:
        logger.exception("Error inesperado en operación %s.", numero)
        print(f"Error inesperado controlado: {exc}")
    else:
        print(resultado)
    finally:
        print("Fin de la operación.")


def ejecutar_simulacion():
    print("=" * 65)
    print("SISTEMA INTEGRAL DE GESTIÓN - SOFTWARE FJ")
    print("SIMULACIÓN DE OPERACIONES Y MANEJO DE EXCEPCIONES")
    print("=" * 65)

    sala = ReservaSalas("SALA-01", 50000, 15)
    equipo = AlquilerEquipos("EQ-01", 120000, "Servidor Rack")
    asesoria = AsesoriaEspecializada("ASES-01", 200000, "Arquitectura Cloud")

    cliente_principal = None
    reserva_principal = None

    def op1():
        nonlocal cliente_principal
        cliente_principal = Cliente(
            "C001", "Carlos Pérez", "carlos.perez@email.com", "3001234567"
        )
        return cliente_principal.obtener_detalles()

    def op2():
        return Cliente(
            "C002", "Ana Gómez", "correo-invalido-sin-arroba", "3119876543"
        ).obtener_detalles()

    def op3():
        return f"{sala.describir_servicio()} Costo 3 horas con IVA: ${sala.calcular_costo(horas=3):,.2f}"

    def op4():
        return ReservaSalas("SALA-MAL", -1000, 5).describir_servicio()

    def op5():
        return (
            f"{equipo.describir_servicio()} Costo 5 días con 10% de descuento: "
            f"${equipo.calcular_costo(dias=5, descuento_porcentaje=10):,.2f}"
        )

    def op6():
        return (
            f"{asesoria.describir_servicio()} Costo de 2 sesiones más tarifa fija: "
            f"${asesoria.calcular_costo(sesiones=2, tarifa_plana_software=50000):,.2f}"
        )

    def op7():
        nonlocal reserva_principal
        reserva_principal = Reserva("RES-101", cliente_principal, sala, 2)
        reserva_principal.confirmar_reserva()
        total = reserva_principal.procesar_reserva(aplicar_impuesto=True)
        return (
            f"Reserva {reserva_principal.id_reserva} - Estado: "
            f"{reserva_principal.estado} - Total: ${total:,.2f}"
        )

    def op8():
        cliente = Cliente("C004", "Luis Torres", "luis.torres@email.com", "3107894561")
        reserva = Reserva("RES-102", cliente, equipo, 2)
        reserva.confirmar_reserva()
        # Se intenta calcular con una duración distinta a la guardada.
        return reserva.procesar_reserva(dias=3, descuento_porcentaje=0)

    def op9():
        return reserva_principal.cancelar_reserva()

    def op10():
        return reserva_principal.cancelar_reserva()

    def op11():
        reserva_pendiente = Reserva("RES-103", cliente_principal, asesoria, 1)
        return reserva_pendiente.procesar_reserva()

    def op12():
        return (
            "Variantes de cálculo: sala con IVA, equipo con descuento y "
            "asesoría con tarifa adicional fueron demostradas en las operaciones 3, 5 y 6."
        )

    operaciones = [
        ("Registro válido de cliente", op1),
        ("Registro inválido de cliente (correo)", op2),
        ("Cálculo de reserva de sala con IVA", op3),
        ("Creación inválida de servicio (costo negativo)", op4),
        ("Alquiler de equipo con descuento", op5),
        ("Asesoría con tarifa adicional", op6),
        ("Creación, confirmación y procesamiento de reserva", op7),
        ("Reserva con duración inconsistente", op8),
        ("Intento de cancelar una reserva procesada", op9),
        ("Segundo intento de cancelar la misma reserva", op10),
        ("Intento de procesar una reserva no confirmada", op11),
        ("Demostración de variantes de cálculo", op12),
    ]

    for numero, (descripcion, funcion) in enumerate(operaciones, start=1):
        ejecutar_operacion(numero, descripcion, funcion)

    print("\n" + "=" * 65)
    print("RESUMEN DE LA SIMULACIÓN")
    print("Se ejecutaron 12 operaciones, con casos válidos e inválidos.")
    print("Los eventos y errores se registraron en sistema_software_fj.log.")
    print("=" * 65)


if __name__ == "__main__":
    ejecutar_simulacion()
