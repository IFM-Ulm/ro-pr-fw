function byte_out = value2byte( value, format )
	
	if(strcmp(format, 'u32'))
		numbytes = 4;
	elseif(strcmp(format, 'u16'))
		numbytes = 2;
	elseif(strcmp(format, 'u8'))
		numbytes = 1;
	elseif(strcmp(format, 'vector'))
		numbytes = ceil(log2(abs(value))/8);
	else
		error('byte format not supported')
	end
	
	value = double(value);
	
	if(value < 0)
		error('conversion of negative numbers not supported');
	end

	if(abs(value - floor(value)) > 0)
		error('conversion of values with fractional parts not supported');
	end
	
	if(~isreal(value))
		error('conversion of complex numbers not supported (how should it?)');
	end
	
	byte_out = uint8(zeros(1,numbytes));
	
	remain = value;
	for b = numbytes : -1 : 1
		
		temp = floor(remain / 2^(8*(b-1)));
		
		byte_out(b) = uint8(temp);
		
		remain = remain - temp * 2^(8*(b-1));
		
	end

end