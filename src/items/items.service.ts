import { Injectable } from '@nestjs/common';

@Injectable()
export class ItemsService {
  private readonly items = [{ id: 1, name: 'Item 1' }, { id: 2, name: 'Item 2' }];

  findAll() {
    return this.items;
  }
}
