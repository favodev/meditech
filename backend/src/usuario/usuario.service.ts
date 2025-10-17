import { Injectable, NotFoundException } from '@nestjs/common';
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
}
