function values = bytes2values(bytes, data_width)

	byte_len = size(bytes,1) * size(bytes,2);

	switch data_width
		case 1
			values = zeros(byte_len * 8, 1);
			offset = 1;
			for b = 1 : byte_len
				value = bytes(b);
				bin_byte = dec2bin(value,8);
				bin_byte = 0+(bin_byte == '1');
				bin_byte = bin_byte(end:-1:1);
				for t = 1 : 8
					values(offset,1) = bin_byte(t);
					offset = offset + 1;
				end
			end
			
		case 2
			values = zeros(byte_len * 4, 1);
			offset = 1;
			for b = 1 : byte_len
				value = bytes(b);
				bin_byte = dec2bin(value,8);
				bin_byte = 0+(bin_byte == '1');
				bin_byte = bin_byte(end:-1:1);
				for t = 1 : 2 : 8
					values(offset,1) = bin_byte(t) + bin_byte(t+1)*2^1;
					offset = offset + 1;
				end
			end
		case 4
			values = zeros(byte_len * 2, 1);
			offset = 1;
			for b = 1 : byte_len
				value = bytes(b);
				bin_byte = dec2bin(value,8);
				bin_byte = 0+(bin_byte == '1');
				bin_byte = bin_byte(end:-1:1);
				for t = 1 : 4 : 8
					values(offset,1) = bin_byte(t) + bin_byte(t+1)*2^1 + bin_byte(t+2)*2^2 + bin_byte(t+3)*2^3;
					offset = offset + 1;
				end
			end
		case 8
			values = double(bytes);
		case 16
			values = zeros(byte_len / 2, 1);
			offset = 1;
			for b = 1 : 2 : byte_len
				values(offset,1) = bytes(b) + bytes(b+1)*2^8;
				offset = offset + 1;
			end
		case 32
			values = zeros(byte_len / 4, 1);
			offset = 1;
			for b = 1 : 4 : byte_len
				values(offset,1) = bytes(b) + bytes(b+1)*2^8 + bytes(b+2)*2^16 + bytes(b+3)*2^24;
				offset = offset + 1;
			end
		otherwise
			error('invalid data_width')
	end
	
end