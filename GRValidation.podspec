Pod::Spec.new do |s|
	s.name     = 'GRValidation'
	s.version  = '0.2.0'
	s.license  = { :type => 'MIT', :file => 'LICENSE' }
	s.summary  = 'Validation toolkit for Swift.'
	s.homepage = 'https://github.com/groue/GRValidation'
	s.author   = { 'Gwendal Roué' => 'gr@pierlis.com' }
	s.source   = { :git => 'https://github.com/groue/GRValidation.git', :tag => "v#{s.version}" }
	s.source_files = 'Validation/**/*.{h,m,swift}'
	s.module_name = 'Validation'
	s.ios.deployment_target = '8.0'
	s.osx.deployment_target = '10.9'
	s.requires_arc = true
	s.framework = 'Foundation'
end
