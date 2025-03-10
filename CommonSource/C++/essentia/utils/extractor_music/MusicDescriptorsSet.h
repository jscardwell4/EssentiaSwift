/*
 * Copyright (C) 2006-2016  Music Technology Group - Universitat Pompeu Fabra
 *
 * This file is part of Essentia
 *
 * Essentia is free software: you can redistribute it and/or modify it under
 * the terms of the GNU Affero General Public License as published by the Free
 * Software Foundation (FSF), either version 3 of the License, or (at your
 * option) any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the Affero GNU General Public License
 * version 3 along with this program.  If not, see http://www.gnu.org/licenses/
 */

#ifndef MUSIC_DESCRIPTOR_SET_H
#define MUSIC_DESCRIPTOR_SET_H


#include "../../streaming/sourcebase.h"
#include "../../pool.h"
#include "../../types.h"
#include "../../essentiamath.h"
#include "../../algorithm.h"
#include "../../scheduler/network.h"
#include "../../streaming/streamingalgorithm.h"
#include "../../algorithmfactory.h"
#include "../../streaming/algorithms/poolstorage.h"
#include "../../streaming/algorithms/vectorinput.h"

using namespace std;
using namespace essentia;
using namespace essentia::streaming;

class MusicDescriptorSet { 

 public:
 	static const string nameSpace;  

 protected:
  Pool options;

};

#endif
