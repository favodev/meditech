import { Transform } from 'class-transformer';
import {
  registerDecorator,
  ValidationOptions,
  ValidatorConstraint,
  ValidatorConstraintInterface,
  ValidationArguments,
} from 'class-validator';

function formatRUT(value: unknown): string {
  if (typeof value !== 'string') return value as string;
  return value.replace(/\./g, '').toUpperCase();
}

export function ToFormattedRUT(): PropertyDecorator {
  return Transform(({ value }) => formatRUT(value));
}

@ValidatorConstraint({ name: 'isValidRUT', async: false })
export class IsValidRUTConstraint implements ValidatorConstraintInterface {
  validate(value: string, args: ValidationArguments) {
    if (typeof value !== 'string') return false;

    const rutRegex = /^[0-9]{7,8}-[0-9K]$/;
    if (!rutRegex.test(value)) return false;

    return algoritmoModulo11(value);
  }

  defaultMessage(args: ValidationArguments) {
    return 'El RUT no es válido o tiene un formato incorrecto.';
  }
}

function algoritmoModulo11(rut: string): boolean {
  const [body, dv] = rut.split('-');
  let sum = 0;
  let multiplier = 2;

  for (let i = body.length - 1; i >= 0; i--) {
    sum += parseInt(body.charAt(i), 10) * multiplier;
    multiplier = multiplier === 7 ? 2 : multiplier + 1;
  }
  const remainder = sum % 11;
  const calculatedDV = 11 - remainder;

  let dvExpected: string;
  if (calculatedDV === 11) {
    dvExpected = '0';
  } else if (calculatedDV === 10) {
    dvExpected = 'K';
  } else {
    dvExpected = calculatedDV.toString();
  }
  return dvExpected === dv;
}

export function IsValidRUT(
  validationOptions?: ValidationOptions,
): PropertyDecorator {
  return function (object: Object, propertyName: string) {
    registerDecorator({
      target: object.constructor,
      propertyName: propertyName,
      options: validationOptions,
      constraints: [],
      validator: IsValidRUTConstraint,
    });
  };
}

export function IsRUT(
  validationOptions?: ValidationOptions,
): PropertyDecorator {
  return function (target: object, propertyName: string) {
    ToFormattedRUT()(target, propertyName);
    IsValidRUT(validationOptions)(target, propertyName);
  };
}
