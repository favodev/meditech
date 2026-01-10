import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Usuario } from './entities/usuario.schema';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsuarioService {
  constructor(@InjectModel(Usuario.name) private userModel: Model<Usuario>) {}

  async findMyProfile(userId: string): Promise<Usuario> {
    const user = await this.userModel
      .findById(userId, {
        password_hash: 0,
        currentHashedRefreshToken: 0,
      })
      .exec();

    if (!user) {
      throw new NotFoundException('Usuario no encontrado.');
    }
    return user;
  }

  async updateMyProfile(
    userId: string,
    updateProfileDto: UpdateProfileDto,
  ): Promise<Usuario> {
    const updatedUser = await this.userModel
      .findByIdAndUpdate(userId, updateProfileDto, { new: true })
      .select('-password_hash -currentHashedRefreshToken');

    if (!updatedUser) {
      throw new NotFoundException('Usuario no encontrado.');
    }
    return updatedUser;
  }

  async calcularDosisSemanal(userId: string) {
    const user = await this.userModel.findById(userId);

    // Ajuste: Accedemos directamente a user.datos_anticoagulacion ya que Object.assign los aplanó
    if (!user || !user.datos_anticoagulacion) {
      throw new BadRequestException('El perfil clínico no ha sido configurado.');
    }

    const { mg_por_pastilla, medicamento } = user.datos_anticoagulacion;

    const dosisDiariaBase = 5.0; // Lógica provisional
    const totalSemanalMg = dosisDiariaBase * 7;
    const totalPastillasSemanal = totalSemanalMg / mg_por_pastilla;

    return {
      medicamento,
      miligramos_semanales: parseFloat(totalSemanalMg.toFixed(2)),
      pastillas_semanales: parseFloat(totalPastillasSemanal.toFixed(2)),
      dosis_diaria_sugerida: parseFloat(dosisDiariaBase.toFixed(2)),
    };
  }
}
